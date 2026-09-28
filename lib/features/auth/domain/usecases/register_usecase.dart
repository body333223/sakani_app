import 'package:equatable/equatable.dart';
import 'package:sakani/core/usecase/usecase.dart';
import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/auth/domain/entities/user_entity.dart';
import 'package:sakani/features/auth/domain/repositories/auth_repository.dart';

class RegisterParams extends Equatable {
  final String email;
  final String password;
  final String name;
  final String phone;
  final String role;
  final String? photoUrl;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
    required this.role,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [email, password, name, phone, role, photoUrl];
}

class RegisterUseCase implements UseCase<UserEntity, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Result<UserEntity>> call(RegisterParams params) {
    return repository.registerWithEmail(
      email: params.email,
      password: params.password,
      name: params.name,
      phone: params.phone,
      role: params.role,
      photoUrl: params.photoUrl,
    );
  }
}
