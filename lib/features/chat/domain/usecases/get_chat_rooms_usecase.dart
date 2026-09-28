import 'package:sakani/features/chat/domain/entities/chat_entities.dart';
import 'package:sakani/features/chat/domain/repositories/chat_repository.dart';

class GetChatRoomsUseCase {
  final ChatRepository repository;

  GetChatRoomsUseCase(this.repository);

  Stream<List<ChatRoomEntity>> call(String userId) {
    return repository.getChatRooms(userId);
  }
}
