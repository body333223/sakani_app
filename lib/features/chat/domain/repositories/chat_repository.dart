import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/chat/domain/entities/chat_entities.dart';

abstract class ChatRepository {
  Stream<List<ChatRoomEntity>> getChatRooms(String userId);

  Stream<List<ChatMessageEntity>> getMessages(String roomId);

  Future<Result<void>> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String text,
  });

  Future<Result<ChatRoomEntity>> createRoom({
    required String apartmentId,
    required String apartmentTitle,
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String ownerName,
  });
}
