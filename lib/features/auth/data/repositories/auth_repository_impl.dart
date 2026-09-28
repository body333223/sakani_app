import 'dart:async';
import 'package:sakani/core/error/exceptions.dart';
import 'package:sakani/core/error/failures.dart';
import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:sakani/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:sakani/features/auth/data/models/user_model.dart';
import 'package:sakani/features/auth/domain/entities/user_entity.dart';
import 'package:sakani/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final StreamController<UserEntity?> _authStateController =
      StreamController<UserEntity?>.broadcast();
  UserEntity? _currentUser;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  }) {
    _currentUser = localDataSource.getCachedUser();
    if (_currentUser != null) {
      _authStateController.add(_currentUser);
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges => _authStateController.stream;

  @override
  UserEntity? get currentUser => _currentUser;

  @override
  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      _persist(user);
      return Success(user);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return FailureResult(NetworkFailure(e.message));
    } catch (e) {
      return FailureResult(ServerFailure('حدث خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Result<UserEntity>> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? photoUrl,
  }) async {
    try {
      final user = await remoteDataSource.registerWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
        photoUrl: photoUrl,
      );
      _persist(user);
      return Success(user);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return FailureResult(NetworkFailure(e.message));
    } catch (e) {
      return FailureResult(ServerFailure('حدث خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Result<UserEntity?>> getUserData(String uid) async {
    try {
      final user = await remoteDataSource.getUserData(uid);
      if (user != null) {
        _persist(user);
        return Success(user);
      }
      return Success(_currentUser);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message, e.statusCode));
    } catch (e) {
      return Success(_currentUser);
    }
  }

  @override
  Future<Result<void>> signOut() async {
    _currentUser = null;
    localDataSource.clearCache();
    _authStateController.add(null);
    return const Success(null);
  }

  @override
  Future<Result<void>> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      final updated = await remoteDataSource.updateProfile(uid, data);
      _persist(updated);
      return const Success(null);
    } catch (_) {
      if (_currentUser != null) {
        final currentModel = UserModel(
          uid: _currentUser!.uid,
          email: _currentUser!.email,
          name: data['name'] ?? _currentUser!.name,
          phone: data['phone'] ?? _currentUser!.phone,
          role: _currentUser!.role,
          photoUrl: data['photoUrl'] ?? _currentUser!.photoUrl,
          createdAt: _currentUser!.createdAt,
        );
        _persist(currentModel);
      }
      return const Success(null);
    }
  }

  void _persist(UserModel user) {
    _currentUser = user;
    localDataSource.cacheUser(user);
    _authStateController.add(user);
  }
}
