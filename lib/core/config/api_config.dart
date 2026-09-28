import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../security/secure_storage_service.dart';

/// تكوين نقاط الوصول (API Configuration) مع تشفير التوكنات
class ApiConfig {
  static const String _tokenKey = '__sakani_auth_secure_token__';

  /// الحصول على التوكن مشفراً من المخزن الآمن
  static String? get token => SecureStorageService.getString(_tokenKey);

  /// حفظ التوكن مشفراً
  static set token(String? value) {
    if (value != null && value.isNotEmpty) {
      SecureStorageService.setString(_tokenKey, value);
    } else {
      SecureStorageService.remove(_tokenKey);
    }
  }

  /// رابط الخادم الأساسي
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api';
      }
    } catch (_) {
      // Fallback for web or desktop
    }
    return 'http://localhost:5000/api';
  }

  /// ترويسات الطلب مع التوكن المشفر
  static Map<String, String> get authHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };
    final currentToken = token;
    if (currentToken != null && currentToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $currentToken';
    }
    return headers;
  }

  // Auth endpoints
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get me => '$baseUrl/auth/me';
  static String user(String uid) => '$baseUrl/auth/users/$uid';

  // Apartments endpoints
  static String get apartments => '$baseUrl/apartments';
  static String apartment(String id) => '$baseUrl/apartments/$id';
  static String ownerApartments(String ownerId) => '$baseUrl/apartments/owner/$ownerId';
  static String toggleAvailability(String id) => '$baseUrl/apartments/$id/availability';
  static String get uploadImages => '$baseUrl/apartments/upload-images';

  // Bookings endpoints
  static String get bookings => '$baseUrl/bookings';
  static String tenantBookings(String tenantId) => '$baseUrl/bookings/tenant/$tenantId';
  static String ownerBookings(String ownerId) => '$baseUrl/bookings/owner/$ownerId';
  static String updateBookingStatus(String id) => '$baseUrl/bookings/$id/status';

  // Chat endpoints
  static String userRooms(String userId) => '$baseUrl/chat/rooms/$userId';
  static String get createRoom => '$baseUrl/chat/rooms';
  static String roomMessages(String roomId) => '$baseUrl/chat/rooms/$roomId/messages';
  static String sendMessage(String roomId) => '$baseUrl/chat/rooms/$roomId/messages';

  // Constants
  static String get constants => '$baseUrl/constants';
}