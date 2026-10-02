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

  static const String _customBaseUrlKey = '__sakani_custom_base_url__';

  /// رابط مخصص يمكن ضبطه ديناميكياً
  static String? get customBaseUrl => SecureStorageService.getString(_customBaseUrlKey);
  static set customBaseUrl(String? value) {
    if (value != null && value.isNotEmpty) {
      SecureStorageService.setString(_customBaseUrlKey, value);
    } else {
      SecureStorageService.remove(_customBaseUrlKey);
    }
  }

  /// مهلة طلبات الشبكة
  static const Duration requestTimeout = Duration(seconds: 15);

  /// رابط الخادم الرسمي المباشر عبر الإنترنت (HTTPS) الدائم والثابت
  static const String liveServerUrl = 'https://prodigal-overpower-nail.ngrok-free.dev/api';
  static const String localServerUrl = 'http://192.168.1.24:5093/api';

  /// رابط الخادم الأساسي
  static String get baseUrl {
    final custom = customBaseUrl;
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return liveServerUrl;
  }

  /// ترويسات الطلب مع التوكن المشفر وتخطي صفحة تحذير ngrok
  static Map<String, String> get authHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'ngrok-skip-browser-warning': 'true',
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

  // Support & Dashboard endpoints
  static String get supportTickets => '$baseUrl/support/tickets';
  static String userSupportTickets(String userId) => '$baseUrl/support/tickets/user/$userId';
  static String ticketMessages(String ticketId) => '$baseUrl/support/tickets/$ticketId/messages';
  static String sendTicketMessage(String ticketId) => '$baseUrl/support/tickets/$ticketId/messages';

  // Constants
  static String get constants => '$baseUrl/constants';
}