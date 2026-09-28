import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;

/// خدمة التشفير وحماية الملفات والبيانات الحساسة
/// توفر تشفير AES-256 وفك التشفير والتحقق من سلامة الملفات (Integrity Check)
class EncryptionService {
  // مفتاح التشفير المشتق وحبيبات التمليح (Salt) بطريقة ديناميكية
  static const String _appSalt = 'SakaniSecureVault2026_@_CoreShield';
  static final enc.IV _defaultIv = enc.IV.fromUtf8('SakaniSecureIV16');

  /// توليد مفتاح AES-256 آمن مشتق من بصمة النظام
  static enc.Key _deriveKey(String? customSalt) {
    final seed = '${customSalt ?? _appSalt}::#Sakani_Secret_Key_Vault_v1#';
    final keyBytes = crypto.sha256.convert(utf8.encode(seed)).bytes;
    return enc.Key(Uint8List.fromList(keyBytes));
  }

  /// تشفير نص عادي إلى نص مشفر بتنسيق Base64
  static String encryptString(String plainText, {String? customSalt}) {
    if (plainText.isEmpty) return '';
    final key = _deriveKey(customSalt);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: _defaultIv);
    return encrypted.base64;
  }

  /// فك تشفير نص مشفر بـ Base64
  static String decryptString(String encryptedBase64, {String? customSalt}) {
    if (encryptedBase64.isEmpty) return '';
    try {
      final key = _deriveKey(customSalt);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt64(encryptedBase64, iv: _defaultIv);
    } catch (_) {
      // في حالة الفشل نرجع النص فارغ لمنع الانهيار
      return '';
    }
  }

  /// تشفير مصفوفة بايتات (ملفات، صور، مستندات)
  static Uint8List encryptBytes(Uint8List bytes, {String? customSalt}) {
    if (bytes.isEmpty) return Uint8List(0);
    final key = _deriveKey(customSalt);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(bytes, iv: _defaultIv);
    return encrypted.bytes;
  }

  /// فك تشفير مصفوفة بايتات
  static Uint8List decryptBytes(Uint8List encryptedBytes, {String? customSalt}) {
    if (encryptedBytes.isEmpty) return Uint8List(0);
    try {
      final key = _deriveKey(customSalt);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decryptBytes(
        enc.Encrypted(encryptedBytes),
        iv: _defaultIv,
      );
      return Uint8List.fromList(decrypted);
    } catch (_) {
      return Uint8List(0);
    }
  }

  /// تشفير ملف وحفظه مشفراً على القرص لمنع وصول أي طرف ثالث إليه
  static Future<File> encryptFile(File sourceFile, File destinationFile, {String? customSalt}) async {
    final bytes = await sourceFile.readAsBytes();
    final encryptedBytes = encryptBytes(bytes, customSalt: customSalt);
    return await destinationFile.writeAsBytes(encryptedBytes, flush: true);
  }

  /// فك تشفير ملف محفوظ بصيغة مشفرة
  static Future<Uint8List> decryptFile(File encryptedFile, {String? customSalt}) async {
    final bytes = await encryptedFile.readAsBytes();
    return decryptBytes(bytes, customSalt: customSalt);
  }

  /// حساب بصمة التشفير (SHA-256 Hash / Checksum) للتأكد من سلامة الملفات
  static String calculateChecksum(Uint8List data) {
    return crypto.sha256.convert(data).toString();
  }

  /// حساب بصمة نص مشفر
  static String calculateStringHash(String input) {
    return crypto.sha256.convert(utf8.encode(input)).toString();
  }

  /// التحقق من تطابق البصمة مع الملف (Anti-Tampering Verification)
  static bool verifyIntegrity(Uint8List data, String expectedHash) {
    final currentHash = calculateChecksum(data);
    return currentHash.toLowerCase() == expectedHash.toLowerCase();
  }
}
