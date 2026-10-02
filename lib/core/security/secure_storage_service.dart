import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'encryption_service.dart';

/// مخزن البيانات المشفر (Secure Encrypted Storage)
/// يضمن تخزين الـ Tokens والبيانات الحساسة وجلسات المستخدم مشفرة بـ AES-256
/// مع حفظ دائم على القرص عبر SharedPreferences
class SecureStorageService {
  static final Map<String, String> _encryptedCache = {};
  static SharedPreferences? _prefs;

  /// تهيئة المخزن وتحميل البيانات المشفرة إلى الذاكرة
  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final keys = _prefs!.getKeys();
      for (final k in keys) {
        if (k.startsWith('sec_')) {
          final val = _prefs!.getString(k);
          if (val != null) {
            _encryptedCache[k.replaceFirst('sec_', '')] = val;
          }
        }
      }
    } catch (_) {}
  }

  /// حفظ قيمة مشفرة بالمفتاح
  static void setString(String key, String value) {
    final encryptedKey = EncryptionService.calculateStringHash(key);
    final encryptedValue = EncryptionService.encryptString(value);
    _encryptedCache[encryptedKey] = encryptedValue;
    _prefs?.setString('sec_$encryptedKey', encryptedValue);
  }

  /// استرجاع وفك تشفير القيمة
  static String? getString(String key) {
    final encryptedKey = EncryptionService.calculateStringHash(key);
    var encryptedValue = _encryptedCache[encryptedKey];
    if (encryptedValue == null && _prefs != null) {
      encryptedValue = _prefs!.getString('sec_$encryptedKey');
      if (encryptedValue != null) {
        _encryptedCache[encryptedKey] = encryptedValue;
      }
    }
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
    _prefs?.remove('sec_$encryptedKey');
  }

  /// مسح كافة البيانات المخزنة فوراً
  static void clearAll() {
    _encryptedCache.clear();
    final keys = _prefs?.getKeys().where((k) => k.startsWith('sec_')).toList() ?? [];
    for (final k in keys) {
      _prefs?.remove(k);
    }
  }
}
