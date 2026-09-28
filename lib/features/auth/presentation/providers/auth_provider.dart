import 'package:flutter/foundation.dart';
import 'package:sakani/features/auth/data/models/user_model.dart';
import 'package:sakani/features/auth/data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  AppUser? _user;
  bool _isLoading = false;
  String? _error;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;
  bool get isOwner => _user?.role == 'owner';
  bool get isTenant => _user?.role == 'tenant';

  AuthProvider() {
    _user = _authService.currentUser;
    _authService.authStateChanges.listen((appUser) {
      _user = appUser;
      notifyListeners();
    });
  }

  Future<void> loadUser(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.getUserData(uid);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.signInWithEmail(email, password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? photoUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _authService.registerWithEmail(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
        photoUrl: photoUrl,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    await _authService.signOut();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? photoUrl,
  }) async {
    if (_user == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = <String, dynamic>{
        'name': name,
        'phone': phone,
      };
      if (photoUrl != null) {
        data['photoUrl'] = photoUrl;
      }
      await _authService.updateProfile(_user!.uid, data);
      await loadUser(_user!.uid);
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfilePhoto(String photoPath) async {
    if (_user == null) return false;
    try {
      await _authService.updateProfile(_user!.uid, {'photoUrl': photoPath});
      _user = _user!.copyWith(photoUrl: photoPath);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
