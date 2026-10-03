import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakani/core/usecase/usecase.dart';
import 'package:sakani/features/auth/domain/entities/user_entity.dart';
import 'package:sakani/features/auth/domain/repositories/auth_repository.dart';
import 'package:sakani/features/auth/domain/usecases/login_usecase.dart';
import 'package:sakani/features/auth/domain/usecases/logout_usecase.dart';
import 'package:sakani/features/auth/domain/usecases/register_usecase.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final AuthRepository authRepository;
  StreamSubscription<UserEntity?>? _authSubscription;

  AuthCubit({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.authRepository,
  }) : super(const AuthInitial()) {
    _checkInitialAuth();
  }

  void _checkInitialAuth() {
    final current = authRepository.currentUser;
    if (current != null) {
      emit(Authenticated(current));
    } else {
      emit(const Unauthenticated());
    }

    _authSubscription = authRepository.authStateChanges.listen((user) {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    });
  }

  UserEntity? get currentUser => switch (state) {
        Authenticated(user: final u) => u,
        _ => authRepository.currentUser,
      };

  bool get isOwner => currentUser?.isOwner ?? false;
  bool get isTenant => currentUser?.isTenant ?? false;

  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    final result = await loginUseCase(LoginParams(email: email, password: password));

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> register({
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
  }) async {
    emit(const AuthLoading());
    final result = await registerUseCase(RegisterParams(
      email: email,
      password: password,
      name: name,
      phone: phone,
      role: role,
      photoUrl: photoUrl,
      nationalId: nationalId,
      idFrontPath: idFrontPath,
      idBackPath: idBackPath,
      inviteCode: inviteCode,
      isApproved: isApproved,
    ));

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  Future<void> logout() async {
    emit(const AuthLoading());
    await logoutUseCase(const NoParams());
    emit(const Unauthenticated());
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
