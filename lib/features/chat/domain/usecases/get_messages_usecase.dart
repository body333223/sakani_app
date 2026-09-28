import 'package:sakani/features/chat/domain/entities/chat_entities.dart';
import 'package:sakani/features/chat/domain/repositories/chat_repository.dart';

class GetMessagesUseCase {
  final ChatRepository repository;

  GetMessagesUseCase(this.repository);

  Stream<List<ChatMessageEntity>> call(String roomId) {
    return repository.getMessages(roomId);
  }
}
