import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../models/user_model.dart';

/// خدمة المصادقة وإدارة حسابات المستخدمين (Clean Code & Encrypted Security)
class AuthService {
  static const String _userSessionKey = '__sakani_user_session__';
  static final StreamController<AppUser?> _authStateController =
      StreamController<AppUser?>.broadcast();
  static AppUser? _currentUser;

  Stream<AppUser?> get authStateChanges => _authStateController.stream;
  AppUser? get currentUser => _currentUser;

  /// تهيئة الجلسة واسترجاع بيانات المستخدم المشفرة
  static void initializeSession() {
    final cachedUserMap = SecureStorageService.getMap(_userSessionKey);
    if (cachedUserMap != null) {
      final uid = cachedUserMap['uid'] ?? '';
      if (uid.isNotEmpty) {
        _currentUser = AppUser.fromMap(cachedUserMap, uid);
        _authStateController.add(_currentUser);
      }
    }
  }

  /// تسجيل الدخول بالبريد الإلكتروني وكلمة المرور
  Future<AppUser> signInWithEmail(String email, String password) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw Exception('يرجى إدخال البريد الإلكتروني وكلمة المرور');
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.login),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'email': trimmedEmail,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        ApiConfig.token = data['token'];

        final user = AppUser(
          uid: data['uid'] ?? 'u_${DateTime.now().millisecondsSinceEpoch}',
          email: data['email'] ?? trimmedEmail,
          name: data['name'] ?? '',
          phone: data['phone'] ?? '',
          role: data['role'] ?? 'tenant',
          photoUrl: data['photoUrl'],
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'])
              : DateTime.now(),
        );

        _persistUser(user);
        return user;
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        final msg = errorData['message'] ?? 'بيانات الدخول غير صحيحة';
        throw Exception(msg);
      }
    } on http.ClientException {
      throw Exception('تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت');
    } on TimeoutException {
      throw Exception('انتهت مهلة الاتصال بالخادم، يرجى المحاولة مرة أخرى');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('حدث خطأ أثناء تسجيل الدخول: $e');
    }
  }

  /// إنشاء حساب جديد
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? photoUrl,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();

    if (trimmedEmail.isEmpty || password.isEmpty || trimmedName.isEmpty) {
      throw Exception('يرجى استكمال جميع الحقول المطلوبة');
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.register),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'email': trimmedEmail,
              'password': password,
              'name': trimmedName,
              'phone': trimmedPhone,
              'role': role,
              'photoUrl': photoUrl,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        ApiConfig.token = data['token'];

        final user = AppUser(
          uid: data['uid'] ?? 'u_${DateTime.now().millisecondsSinceEpoch}',
          email: data['email'] ?? trimmedEmail,
          name: data['name'] ?? trimmedName,
          phone: data['phone'] ?? trimmedPhone,
          role: data['role'] ?? role,
          photoUrl: data['photoUrl'] ?? photoUrl,
          createdAt: data['createdAt'] != null
              ? DateTime.parse(data['createdAt'])
              : DateTime.now(),
        );

        _persistUser(user);
        return user;
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        final msg = errorData['message'] ?? 'فشل إنشاء الحساب، يرجى التحقق من البيانات';
        throw Exception(msg);
      }
    } on http.ClientException {
      throw Exception('تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت');
    } on TimeoutException {
      throw Exception('انتهت مهلة الاتصال بالخادم، يرجى المحاولة مرة أخرى');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('حدث خطأ أثناء إنشاء الحساب: $e');
    }
  }

  /// جلب بيانات المستخدم
  Future<AppUser?> getUserData(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.user(uid)), headers: ApiConfig.authHeaders)
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final user = AppUser.fromMap(data, uid);
        _persistUser(user);
        return user;
      }
    } catch (_) {
      // Return cached user if network fails
    }
    return _currentUser;
  }

  /// تسجيل الخروج وحذف الجلسة المشفرة
  Future<void> signOut() async {
    _currentUser = null;
    ApiConfig.token = null;
    SecureStorageService.remove(_userSessionKey);
    _authStateController.add(null);
  }

  /// تحديث الملف الشخصي
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      final response = await http
          .put(
            Uri.parse(ApiConfig.user(uid)),
            headers: ApiConfig.authHeaders,
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final updatedData = jsonDecode(utf8.decode(response.bodyBytes));
        final updatedUser = AppUser.fromMap(updatedData, uid);
        _persistUser(updatedUser);
        return;
      }
    } catch (_) {}

    if (_currentUser != null) {
      final updated = _currentUser!.copyWith(
        name: data['name'] ?? _currentUser!.name,
        phone: data['phone'] ?? _currentUser!.phone,
        photoUrl: data['photoUrl'] ?? _currentUser!.photoUrl,
      );
      _persistUser(updated);
    }
  }

  /// حفظ وتحديث المستخدم الحالي
  void _persistUser(AppUser user) {
    syncAppUser(user);
  }

  /// مزامنة المستخدم الحالي عبر التطبيق بالكامل
  static void syncAppUser(AppUser? user) {
    _currentUser = user;
    if (user != null) {
      SecureStorageService.setMap(_userSessionKey, user.toMap());
    } else {
      SecureStorageService.remove(_userSessionKey);
    }
    _authStateController.add(_currentUser);
  }
}