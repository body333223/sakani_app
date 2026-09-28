import 'package:sakani/core/security/secure_storage_service.dart';
import 'package:sakani/features/auth/data/models/user_model.dart';

abstract class AuthLocalDataSource {
  UserModel? getCachedUser();
  void cacheUser(UserModel user);
  void clearCache();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _userSessionKey = '__sakani_user_session__';

  @override
  UserModel? getCachedUser() {
    final cachedUserMap = SecureStorageService.getMap(_userSessionKey);
    if (cachedUserMap != null) {
      final uid = cachedUserMap['uid'] ?? '';
      if (uid.isNotEmpty) {
        return UserModel.fromMap(cachedUserMap, uid);
      }
    }
    return null;
  }

  @override
  void cacheUser(UserModel user) {
    SecureStorageService.setMap(_userSessionKey, user.toMap());
  }

  @override
  void clearCache() {
    SecureStorageService.remove(_userSessionKey);
  }
}
