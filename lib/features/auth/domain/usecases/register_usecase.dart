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
  final String? nationalId;
  final String? idFrontPath;
  final String? idBackPath;
  final String? inviteCode;
  final bool? isApproved;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.name,
    required this.phone,
    required this.role,
    this.photoUrl,
    this.nationalId,
    this.idFrontPath,
    this.idBackPath,
    this.inviteCode,
    this.isApproved,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        name,
        phone,
        role,
        photoUrl,
        nationalId,
        idFrontPath,
        idBackPath,
        inviteCode,
        isApproved,
      ];
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
      nationalId: params.nationalId,
      idFrontPath: params.idFrontPath,
      idBackPath: params.idBackPath,
      inviteCode: params.inviteCode,
      isApproved: params.isApproved,
    );
  }
}
