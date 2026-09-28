import 'dart:async';
import 'package:sakani/core/error/failures.dart';
import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:sakani/features/chat/data/models/chat_message.dart';
import 'package:sakani/features/chat/domain/entities/chat_entities.dart';
import 'package:sakani/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  final List<ChatRoomModel> _cachedRooms = [];
  final Map<String, List<ChatMessageModel>> _cachedMessages = {};

  final StreamController<List<ChatRoomEntity>> _roomsStreamController =
      StreamController<List<ChatRoomEntity>>.broadcast();
  final StreamController<List<ChatMessageEntity>> _messagesStreamController =
      StreamController<List<ChatMessageEntity>>.broadcast();

  String? _activeRoomId;
  Timer? _pollingTimer;

  ChatRepositoryImpl({required this.remoteDataSource});

  void _notifyRooms() {
    _roomsStreamController.add(List.unmodifiable(_cachedRooms));
  }

  void _notifyMessages(String roomId) {
    if (_activeRoomId == roomId) {
      _messagesStreamController.add(List.unmodifiable(_cachedMessages[roomId] ?? []));
    }
  }

  @override
  Stream<List<ChatRoomEntity>> getChatRooms(String userId) {
    _fetchRooms(userId);

    return Stream<List<ChatRoomEntity>>.multi((controller) {
      final initial = _filterRooms(userId);
      controller.add(initial);

      final sub = _roomsStreamController.stream.listen((_) {
        controller.add(_filterRooms(userId));
      });

      controller.onCancel = () => sub.cancel();
    });
  }

  List<ChatRoomEntity> _filterRooms(String userId) {
    final list = _cachedRooms.where((r) =>
        r.participants.contains(userId) ||
        r.tenantId == userId ||
        r.ownerId == userId).toList();
    list.sort((a, b) {
      if (a.lastTimestamp == null) return 1;
      if (b.lastTimestamp == null) return -1;
      return b.lastTimestamp!.compareTo(a.lastTimestamp!);
    });
    return list;
  }

  Future<void> _fetchRooms(String userId) async {
    try {
      final rooms = await remoteDataSource.getChatRooms(userId);
      _cachedRooms.clear();
      _cachedRooms.addAll(rooms);
      _notifyRooms();
    } catch (_) {}
  }

  @override
  Stream<List<ChatMessageEntity>> getMessages(String roomId) {
    _activeRoomId = roomId;
    _fetchMessages(roomId);

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_activeRoomId == roomId) {
        _fetchMessages(roomId);
      }
    });

    return Stream<List<ChatMessageEntity>>.multi((controller) {
      controller.add(List.unmodifiable(_cachedMessages[roomId] ?? []));

      final sub = _messagesStreamController.stream.listen((msgs) {
        if (_activeRoomId == roomId) {
          controller.add(msgs);
        }
      });

      controller.onCancel = () {
        sub.cancel();
        _pollingTimer?.cancel();
      };
    });
  }

  Future<void> _fetchMessages(String roomId) async {
    try {
      final msgs = await remoteDataSource.getMessages(roomId);
      _cachedMessages[roomId] = msgs;
      _notifyMessages(roomId);
    } catch (_) {}
  }

  @override
  Future<Result<void>> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    try {
      final newMsg = ChatMessageModel(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: senderId,
        senderName: senderName,
        text: text,
        timestamp: DateTime.now(),
      );

      _cachedMessages.putIfAbsent(roomId, () => []).add(newMsg);
      _notifyMessages(roomId);

      // update last message in room
      final roomIdx = _cachedRooms.indexWhere((r) => r.id == roomId);
      if (roomIdx != -1) {
        final old = _cachedRooms[roomIdx];
        _cachedRooms[roomIdx] = ChatRoomModel(
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
        _notifyRooms();
      }

      await remoteDataSource.sendMessage(
        roomId: roomId,
        senderId: senderId,
        senderName: senderName,
        text: text,
      );

      return const Success(null);
    } catch (e) {
      return FailureResult(ServerFailure('تعذر إرسال الرسالة: $e'));
    }
  }

  @override
  Future<Result<ChatRoomEntity>> createRoom({
    required String apartmentId,
    required String apartmentTitle,
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String ownerName,
  }) async {
    try {
      final existing = _cachedRooms.where((r) =>
          r.apartmentId == apartmentId && r.tenantId == tenantId).firstOrNull;
      if (existing != null) {
        return Success(existing);
      }

      final room = await remoteDataSource.createRoom(
        apartmentId: apartmentId,
        apartmentTitle: apartmentTitle,
        tenantId: tenantId,
        tenantName: tenantName,
        ownerId: ownerId,
        ownerName: ownerName,
      );

      _cachedRooms.insert(0, room);
      _cachedMessages[room.id] = [];
      _notifyRooms();
      return Success(room);
    } catch (e) {
      return FailureResult(ServerFailure('تعذر إنشاء المحادثة: $e'));
    }
  }
}
