import 'package:equatable/equatable.dart';
import 'package:sakani/core/usecase/usecase.dart';
import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/chat/domain/repositories/chat_repository.dart';

class SendMessageParams extends Equatable {
  final String roomId;
  final String senderId;
  final String senderName;
  final String text;

  const SendMessageParams({
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.text,
  });

  @override
  List<Object?> get props => [roomId, senderId, senderName, text];
}

class SendMessageUseCase implements UseCase<void, SendMessageParams> {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  @override
  Future<Result<void>> call(SendMessageParams params) {
    return repository.sendMessage(
      roomId: params.roomId,
      senderId: params.senderId,
      senderName: params.senderName,
      text: params.text,
    );
  }
}
