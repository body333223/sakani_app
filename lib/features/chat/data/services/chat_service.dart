import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../models/chat_message.dart';

/// خدمة المحادثات الفورية مع التخزين المحلي الدائم والمزامنة السحابية فائقة السرعة
class ChatService {
  static const String _roomsStorageKey = '__sakani_persisted_chat_rooms__';
  static String _messagesStorageKey(String roomId) => '__sakani_persisted_chat_msgs_${roomId}__';

  static final List<ChatRoom> _cachedRooms = [];
  static final Map<String, List<ChatMessage>> _cachedMessages = {};

  static final _roomsStreamController = StreamController<List<ChatRoom>>.broadcast();
  static final _messagesStreamController = StreamController<String>.broadcast();
  static String? _activeRoomId;
  static Timer? _pollingTimer;
  static bool _hasLoadedPersisted = false;

  ChatService() {
    _initPersistence();
  }

  static void _initPersistence() {
    if (_hasLoadedPersisted) return;
    _hasLoadedPersisted = true;
    _loadPersistedRooms();
  }

  static void _loadPersistedRooms() {
    final raw = SecureStorageService.getString(_roomsStorageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List decoded = jsonDecode(raw);
        _cachedRooms.clear();
        for (var item in decoded) {
          _cachedRooms.add(ChatRoom.fromMap(item, item['id'] ?? ''));
        }
      } catch (_) {}
    }
  }

  static void _saveRoomsToStorage() {
    try {
      final list = _cachedRooms.map((r) => r.toMap()).toList();
      SecureStorageService.setString(_roomsStorageKey, jsonEncode(list));
    } catch (_) {}
  }

  static void _loadPersistedMessages(String roomId) {
    final raw = SecureStorageService.getString(_messagesStorageKey(roomId));
    if (raw != null && raw.isNotEmpty) {
      try {
        final List decoded = jsonDecode(raw);
        final list = <ChatMessage>[];
        for (var item in decoded) {
          list.add(ChatMessage.fromMap(item, item['id'] ?? ''));
        }
        _cachedMessages[roomId] = list;
      } catch (_) {}
    }
  }

  static void _saveMessagesToStorage(String roomId) {
    try {
      final msgs = _cachedMessages[roomId] ?? [];
      final list = msgs.map((m) => m.toMap()).toList();
      SecureStorageService.setString(_messagesStorageKey(roomId), jsonEncode(list));
    } catch (_) {}
  }

  void _updateRoomsStream() {
    if (!_roomsStreamController.isClosed) {
      _roomsStreamController.add(List.from(_cachedRooms));
    }
  }

  void _updateMessagesStream(String roomId) {
    if (!_messagesStreamController.isClosed) {
      _messagesStreamController.add(roomId);
    }
  }

  List<ChatRoom> _getFilteredRooms(String userId) {
    final filtered = _cachedRooms.where((r) =>
        r.participants.contains(userId) ||
        r.tenantId == userId ||
        r.ownerId == userId).toList();
    filtered.sort((a, b) {
      if (a.lastTimestamp == null) return 1;
      if (b.lastTimestamp == null) return -1;
      return b.lastTimestamp!.compareTo(a.lastTimestamp!);
    });
    return filtered;
  }

  Stream<List<ChatRoom>> getChatRooms(String userId) {
    _initPersistence();
    _fetchRoomsFromApi(userId);

    final controller = StreamController<List<ChatRoom>>.broadcast();

    void emitLatest() {
      if (!controller.isClosed) {
        controller.add(_getFilteredRooms(userId));
      }
    }

    // Instant zero-delay emit from persistent storage
    scheduleMicrotask(emitLatest);

    final sub = _roomsStreamController.stream.listen((_) {
      emitLatest();
    });

    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  Future<void> _fetchRoomsFromApi(String userId) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.userRooms(userId)), headers: ApiConfig.authHeaders)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        for (var item in data) {
          final room = ChatRoom.fromMap(item, item['id'] ?? '');
          final idx = _cachedRooms.indexWhere((r) => r.id == room.id);
          if (idx != -1) {
            _cachedRooms[idx] = room;
          } else {
            _cachedRooms.add(room);
          }
        }
        _saveRoomsToStorage();
        _updateRoomsStream();
      }
    } catch (_) {}
  }

  Stream<List<ChatMessage>> getMessages(String roomId) {
    _activeRoomId = roomId;
    if (!_cachedMessages.containsKey(roomId) || _cachedMessages[roomId]!.isEmpty) {
      _loadPersistedMessages(roomId);
    }
    _fetchMessagesFromApi(roomId);

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_activeRoomId == roomId) {
        _fetchMessagesFromApi(roomId);
      }
    });

    final controller = StreamController<List<ChatMessage>>.broadcast();

    void emitLatest() {
      if (!controller.isClosed) {
        final list = _cachedMessages[roomId] ?? [];
        controller.add(List.from(list));
      }
    }

    // Instant zero-delay emit so conversation appears immediately
    scheduleMicrotask(emitLatest);

    final sub = _messagesStreamController.stream.listen((updatedRoomId) {
      if (updatedRoomId == roomId) {
        emitLatest();
      }
    });

    controller.onCancel = () {
      sub.cancel();
      _pollingTimer?.cancel();
    };

    return controller.stream;
  }

  Future<void> _fetchMessagesFromApi(String roomId) async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.roomMessages(roomId)), headers: ApiConfig.authHeaders)
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        final list = <ChatMessage>[];
        for (var item in data) {
          list.add(ChatMessage.fromMap(item, item['id'] ?? ''));
        }
        _cachedMessages[roomId] = list;
        _saveMessagesToStorage(roomId);
        _updateMessagesStream(roomId);
      }
    } catch (_) {}
  }

  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final newMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
    );

    if (!_cachedMessages.containsKey(roomId)) {
      _cachedMessages[roomId] = [];
    }
    _cachedMessages[roomId]!.add(newMsg);
    _saveMessagesToStorage(roomId);

    // Update room in memory and storage
    final rIdx = _cachedRooms.indexWhere((r) => r.id == roomId);
    if (rIdx != -1) {
      final old = _cachedRooms[rIdx];
      _cachedRooms[rIdx] = ChatRoom(
        id: old.id,
        apartmentId: old.apartmentId,
        apartmentTitle: old.apartmentTitle,
        tenantId: old.tenantId,
        tenantName: old.tenantName,
        ownerId: old.ownerId,
        ownerName: old.ownerName,
        lastMessage: text,
        lastTimestamp: DateTime.now(),
        participants: old.participants,
      );
      _saveRoomsToStorage();
    }

    _updateMessagesStream(roomId);
    _updateRoomsStream();

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.sendMessage(roomId)),
        headers: ApiConfig.authHeaders,
        body: jsonEncode({
          'roomId': roomId,
          'senderId': senderId,
          'senderName': senderName,
          'text': text,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final serverMsg = ChatMessage.fromMap(data, data['id'] ?? newMsg.id);
        final mIdx = _cachedMessages[roomId]!.indexWhere((m) => m.id == newMsg.id);
        if (mIdx != -1) {
          _cachedMessages[roomId]![mIdx] = serverMsg;
          _saveMessagesToStorage(roomId);
          _updateMessagesStream(roomId);
        }
      }
    } catch (_) {}
  }

  Future<ChatRoom> createRoom({
    required String apartmentId,
    required String apartmentTitle,
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String ownerName,
  }) async {
    _initPersistence();

    final existingIndex = _cachedRooms.indexWhere(
      (r) => (r.apartmentId == apartmentId && r.tenantId == tenantId),
    );
    if (existingIndex != -1) {
      return _cachedRooms[existingIndex];
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.createRoom),
        headers: ApiConfig.authHeaders,
        body: jsonEncode({
          'apartmentId': apartmentId,
          'apartmentTitle': apartmentTitle,
          'tenantId': tenantId,
          'tenantName': tenantName,
          'ownerId': ownerId,
          'ownerName': ownerName,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final room = ChatRoom.fromMap(data, data['id'] ?? '');
        _cachedRooms.insert(0, room);
        _saveRoomsToStorage();
        _updateRoomsStream();
        return room;
      }
    } catch (_) {}

    final newRoom = ChatRoom(
      id: 'room_${apartmentId}_$tenantId',
      apartmentId: apartmentId,
      apartmentTitle: apartmentTitle,
      tenantId: tenantId,
      tenantName: tenantName,
      ownerId: ownerId,
      ownerName: ownerName,
      participants: [tenantId, ownerId],
      lastMessage: '',
      lastTimestamp: DateTime.now(),
    );

    _cachedRooms.insert(0, newRoom);
    _cachedMessages[newRoom.id] = [];
    _saveRoomsToStorage();
    _saveMessagesToStorage(newRoom.id);
    _updateRoomsStream();
    return newRoom;
  }
}