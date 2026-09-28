import 'package:equatable/equatable.dart';
import 'package:sakani/core/usecase/usecase.dart';
import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/chat/domain/entities/chat_entities.dart';
import 'package:sakani/features/chat/domain/repositories/chat_repository.dart';

class CreateRoomParams extends Equatable {
  final String apartmentId;
  final String apartmentTitle;
  final String tenantId;
  final String tenantName;
  final String ownerId;
  final String ownerName;

  const CreateRoomParams({
    required this.apartmentId,
    required this.apartmentTitle,
    required this.tenantId,
    required this.tenantName,
    required this.ownerId,
    required this.ownerName,
  });

  @override
  List<Object?> get props => [
        apartmentId,
        apartmentTitle,
        tenantId,
        tenantName,
        ownerId,
        ownerName,
      ];
}

class CreateRoomUseCase implements UseCase<ChatRoomEntity, CreateRoomParams> {
  final ChatRepository repository;

  CreateRoomUseCase(this.repository);

  @override
  Future<Result<ChatRoomEntity>> call(CreateRoomParams params) {
    return repository.createRoom(
      apartmentId: params.apartmentId,
      apartmentTitle: params.apartmentTitle,
      tenantId: params.tenantId,
      tenantName: params.tenantName,
      ownerId: params.ownerId,
      ownerName: params.ownerName,
    );
  }
}
