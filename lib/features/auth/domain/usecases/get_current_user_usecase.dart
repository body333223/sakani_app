import 'package:sakani/core/usecase/usecase.dart';
import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/auth/domain/entities/user_entity.dart';
import 'package:sakani/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase implements UseCase<UserEntity?, String> {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<Result<UserEntity?>> call(String uid) {
    return repository.getUserData(uid);
  }
}
