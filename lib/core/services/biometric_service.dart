import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sakani/core/security/secure_storage_service.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static const String _keyRememberMe = '__sakani_remember_me__';
  static const String _keyBiometricEnabled = '__sakani_biometric_enabled__';
  static const String _keySavedEmail = '__sakani_saved_email__';
  static const String _keySavedPassword = '__sakani_saved_password__';

  /// هل يدعم الجهاز التحقق بالبصمة أو الوجه؟
  static Future<bool> isBiometricsSupported() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// الحصول على أنواع البصمات المتوفرة (وجه أو إصبع)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// طلب مصادقة البصمة من المستخدم
  static Future<bool> authenticate({
    String reason = 'يرجى تأكيد هويتك باستخدام البصمة لتسجيل الدخول السريع',
  }) async {
    try {
      final isSupported = await isBiometricsSupported();
      if (!isSupported) return false;

      return await _auth.authenticate(
        localizedReason: reason,
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// ─── إدارة حالة "تذكرني" والبيانات المحفوظة ───

  /// هل خيار "تذكرني" مفعل؟
  static bool isRememberMeEnabled() {
    return SecureStorageService.getString(_keyRememberMe) == 'true';
  }

  /// تفعيل أو تعطيل خيار "تذكرني"
  static void setRememberMe(bool enabled) {
    SecureStorageService.setString(_keyRememberMe, enabled ? 'true' : 'false');
  }

  /// هل تسجيل الدخول بالبصمة مفعل؟
  static bool isBiometricLoginEnabled() {
    return SecureStorageService.getString(_keyBiometricEnabled) == 'true';
  }

  /// تفعيل أو تعطيل تسجيل الدخول بالبصمة
  static void setBiometricLoginEnabled(bool enabled) {
    SecureStorageService.setString(_keyBiometricEnabled, enabled ? 'true' : 'false');
  }

  /// حفظ بيانات الدخول مشفرة لاستخدامها مع البصمة و"تذكرني"
  static void saveCredentials({
    required String email,
    required String password,
  }) {
    SecureStorageService.setString(_keySavedEmail, email);
    SecureStorageService.setString(_keySavedPassword, password);
    setRememberMe(true);
    setBiometricLoginEnabled(true);
  }

  /// استرجاع البريد وكلمة المرور المحفوظين
  static Map<String, String>? getSavedCredentials() {
    final email = SecureStorageService.getString(_keySavedEmail);
    final password = SecureStorageService.getString(_keySavedPassword);
    if (email != null && email.isNotEmpty && password != null && password.isNotEmpty) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  /// مسح بيانات الدخول المحفوظة عند تسجيل الخروج أو إلغاء التذكر
  static void clearSavedCredentials() {
    SecureStorageService.remove(_keySavedEmail);
    SecureStorageService.remove(_keySavedPassword);
    setRememberMe(false);
  }
}
