import 'package:equatable/equatable.dart';
import 'package:sakani/core/usecase/usecase.dart';
import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/auth/domain/entities/user_entity.dart';
import 'package:sakani/features/auth/domain/repositories/auth_repository.dart';

class LoginParams extends Equatable {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Result<UserEntity>> call(LoginParams params) {
    return repository.signInWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}
