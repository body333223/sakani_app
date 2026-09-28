import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sakani/core/config/api_config.dart';
import 'package:sakani/core/error/exceptions.dart';
import 'package:sakani/features/auth/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? photoUrl,
  });

  Future<UserModel?> getUserData(String uid);

  Future<UserModel> updateProfile(String uid, Map<String, dynamic> data);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client
          .post(
            Uri.parse(ApiConfig.login),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        ApiConfig.token = data['token'];

        return UserModel(
          uid: data['uid'] ?? 'u_${DateTime.now().millisecondsSinceEpoch}',
          email: data['email'] ?? email.trim(),
          name: data['name'] ?? '',
          phone: data['phone'] ?? '',
          role: data['role'] ?? 'tenant',
          photoUrl: data['photoUrl'],
          createdAt: data['createdAt'] != null
              ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
              : DateTime.now(),
        );
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw ServerException(
          errorData['message'] ?? 'بيانات الدخول غير صحيحة',
          response.statusCode,
        );
      }
    } on http.ClientException {
      throw const NetworkException('تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت');
    } on TimeoutException {
      throw const NetworkException('انتهت مهلة الاتصال بالخادم، يرجى المحاولة مرة أخرى');
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw ServerException('حدث خطأ أثناء تسجيل الدخول: $e');
    }
  }

  @override
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? photoUrl,
  }) async {
    try {
      final response = await client
          .post(
            Uri.parse(ApiConfig.register),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'email': email.trim(),
              'password': password,
              'name': name.trim(),
              'phone': phone.trim(),
              'role': role,
              'photoUrl': photoUrl,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        ApiConfig.token = data['token'];

        return UserModel(
          uid: data['uid'] ?? 'u_${DateTime.now().millisecondsSinceEpoch}',
          email: data['email'] ?? email.trim(),
          name: data['name'] ?? name.trim(),
          phone: data['phone'] ?? phone.trim(),
          role: data['role'] ?? role,
          photoUrl: data['photoUrl'] ?? photoUrl,
          createdAt: data['createdAt'] != null
              ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
              : DateTime.now(),
        );
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw ServerException(
          errorData['message'] ?? 'فشل إنشاء الحساب، يرجى التحقق من البيانات',
          response.statusCode,
        );
      }
    } on http.ClientException {
      throw const NetworkException('تعذر الاتصال بالخادم، يرجى التحقق من اتصال الإنترنت');
    } on TimeoutException {
      throw const NetworkException('انتهت مهلة الاتصال بالخادم، يرجى المحاولة مرة أخرى');
    } catch (e) {
      if (e is ServerException || e is NetworkException) rethrow;
      throw ServerException('حدث خطأ أثناء إنشاء الحساب: $e');
    }
  }

  @override
  Future<UserModel?> getUserData(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final response = await client
          .get(Uri.parse(ApiConfig.user(uid)), headers: ApiConfig.authHeaders)
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return UserModel.fromMap(data, uid);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel> updateProfile(String uid, Map<String, dynamic> data) async {
    final response = await client
        .put(
          Uri.parse(ApiConfig.user(uid)),
          headers: ApiConfig.authHeaders,
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 3));

    if (response.statusCode == 200) {
      final updatedData = jsonDecode(utf8.decode(response.bodyBytes));
      return UserModel.fromMap(updatedData, uid);
    } else {
      throw ServerException('فشل في تحديث الملف الشخصي', response.statusCode);
    }
  }
}
