import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../models/chat_message.dart';

class ChatService {
  static final List<ChatRoom> _cachedRooms = [];
  static final Map<String, List<ChatMessage>> _cachedMessages = {};

  static final _roomsStreamController = StreamController<List<ChatRoom>>.broadcast();
  static final _messagesStreamController = StreamController<List<ChatMessage>>.broadcast();
  static String? _activeRoomId;
  static Timer? _pollingTimer;

  void _updateRoomsStream() {
    _roomsStreamController.add(List.from(_cachedRooms));
  }

  void _updateMessagesStream(String roomId) {
    if (_activeRoomId == roomId) {
      final list = _cachedMessages[roomId] ?? [];
      _messagesStreamController.add(List.from(list));
    }
  }

  Stream<List<ChatRoom>> getChatRooms(String userId) {
    _fetchRoomsFromApi(userId);
    return _roomsStreamController.stream.map((list) {
      final filtered = list.where((r) => r.participants.contains(userId) || r.tenantId == userId || r.ownerId == userId).toList();
      filtered.sort((a, b) {
        if (a.lastTimestamp == null) return 1;
        if (b.lastTimestamp == null) return -1;
        return b.lastTimestamp!.compareTo(a.lastTimestamp!);
      });
      return filtered;
    });
  }

  Future<void> _fetchRoomsFromApi(String userId) async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.userRooms(userId)), headers: ApiConfig.authHeaders).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        _cachedRooms.clear();
        for (var item in data) {
          _cachedRooms.add(ChatRoom.fromMap(item, item['id'] ?? ''));
        }
        _updateRoomsStream();
      }
    } catch (_) {}
  }

  Stream<List<ChatMessage>> getMessages(String roomId) {
    _activeRoomId = roomId;
    _fetchMessagesFromApi(roomId);

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_activeRoomId == roomId) {
        _fetchMessagesFromApi(roomId);
      }
    });

    return _messagesStreamController.stream;
  }

  Future<void> _fetchMessagesFromApi(String roomId) async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.roomMessages(roomId)), headers: ApiConfig.authHeaders).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        final list = <ChatMessage>[];
        for (var item in data) {
          list.add(ChatMessage.fromMap(item, item['id'] ?? ''));
        }
        _cachedMessages[roomId] = list;
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
        final msg = ChatMessage.fromMap(data, data['id'] ?? '');
        if (!_cachedMessages.containsKey(roomId)) {
          _cachedMessages[roomId] = [];
        }
        _cachedMessages[roomId]!.add(msg);
        _updateMessagesStream(roomId);
        _fetchRoomsFromApi(senderId);
        return;
      }
    } catch (_) {}

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
    _updateMessagesStream(roomId);
    _updateRoomsStream();
  }

  Future<ChatRoom> createRoom({
    required String apartmentId,
    required String apartmentTitle,
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String ownerName,
  }) async {
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

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final room = ChatRoom.fromMap(data, data['id'] ?? '');
        final idx = _cachedRooms.indexWhere((r) => r.id == room.id);
        if (idx != -1) {
          _cachedRooms[idx] = room;
        } else {
          _cachedRooms.insert(0, room);
        }
        _updateRoomsStream();
        return room;
      }
    } catch (_) {}

    final existingIndex = _cachedRooms.indexWhere(
      (r) => r.apartmentId == apartmentId && r.tenantId == tenantId,
    );
    if (existingIndex != -1) {
      return _cachedRooms[existingIndex];
    }

    final newRoom = ChatRoom(
      id: 'room_${DateTime.now().millisecondsSinceEpoch}',
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

    _cachedRooms.add(newRoom);
    _cachedMessages[newRoom.id] = [];
    _updateRoomsStream();
    return newRoom;
  }
}