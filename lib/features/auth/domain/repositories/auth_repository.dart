import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;

  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<UserEntity>> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? photoUrl,
    String? nationalId,
    String? idFrontPath,
    String? idBackPath,
    String? inviteCode,
    bool? isApproved,
  });

  Future<Result<UserEntity?>> getUserData(String uid);

  Future<Result<void>> signOut();

  Future<Result<void>> updateProfile(String uid, Map<String, dynamic> data);
}
