import 'dart:convert';
import 'encryption_service.dart';

/// مخزن البيانات المشفر (Secure Encrypted Storage)
/// يضمن تخزين الـ Tokens والبيانات الحساسة وجلسات المستخدم مشفرة بـ AES-256
class SecureStorageService {
  static final Map<String, String> _encryptedCache = {};

  /// حفظ قيمة مشفرة بالمفتاح
  static void setString(String key, String value) {
    final encryptedKey = EncryptionService.calculateStringHash(key);
    final encryptedValue = EncryptionService.encryptString(value);
    _encryptedCache[encryptedKey] = encryptedValue;
  }

  /// استرجاع وفك تشفير القيمة
  static String? getString(String key) {
    final encryptedKey = EncryptionService.calculateStringHash(key);
    final encryptedValue = _encryptedCache[encryptedKey];
    if (encryptedValue == null || encryptedValue.isEmpty) return null;
    final decrypted = EncryptionService.decryptString(encryptedValue);
    return decrypted.isNotEmpty ? decrypted : null;
  }

  /// حفظ كائن Map مشفر بتنسيق JSON
  static void setMap(String key, Map<String, dynamic> map) {
    final jsonStr = jsonEncode(map);
    setString(key, jsonStr);
  }

  /// استرجاع كائن Map مفكوك التشفير
  static Map<String, dynamic>? getMap(String key) {
    final decryptedStr = getString(key);
    if (decryptedStr == null || decryptedStr.isEmpty) return null;
    try {
      return jsonDecode(decryptedStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// حذف مفتاح
  static void remove(String key) {
    final encryptedKey = EncryptionService.calculateStringHash(key);
    _encryptedCache.remove(encryptedKey);
  }

  /// مسح كافة البيانات المخزنة فوراً
  static void clearAll() {
    _encryptedCache.clear();
  }
}
