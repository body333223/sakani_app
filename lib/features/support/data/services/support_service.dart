import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../models/support_ticket_model.dart';

/// خدمة الدعم الفني المباشر وتنسيق التذاكر مع لوحة التحكم
class SupportService {
  static const String _activeTicketStorageKey = '__sakani_support_active_ticket__';
  static String _ticketMessagesKey(String id) => '__sakani_support_msgs_${id}__';

  /// إنشاء تذكرة دعم فني جديدة موجهة تلقائياً لشيفت الموظف المتاح
  static Future<SupportTicketModel?> createTicket({
    required String userId,
    required String userName,
    String? userEmail,
    String? userPhone,
    required String subject,
    required String initialMessage,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.supportTickets);
      final body = jsonEncode({
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail ?? '',
        'userPhone': userPhone ?? '',
        'subject': subject,
        'initialMessage': initialMessage,
      });

      final response = await http
          .post(url, headers: ApiConfig.authHeaders, body: body)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final ticket = SupportTicketModel.fromJson(data);
        saveActiveTicketId(ticket.id);
        return ticket;
      }
    } catch (e) {
      debugPrint('[SupportService] Error creating ticket: $e');
    }
    return null;
  }

  /// جلب تذاكر المستخدم الحالية
  static Future<List<SupportTicketModel>> getUserTickets(String userId) async {
    try {
      final url = Uri.parse(ApiConfig.userSupportTickets(userId));
      final response = await http
          .get(url, headers: ApiConfig.authHeaders)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((item) => SupportTicketModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('[SupportService] Error fetching tickets: $e');
    }
    return [];
  }

  /// جلب رسائل تذكرة معينة
  static Future<List<SupportMessageModel>> getTicketMessages(String ticketId) async {
    try {
      final url = Uri.parse(ApiConfig.ticketMessages(ticketId));
      final response = await http
          .get(url, headers: ApiConfig.authHeaders)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        final messages = data.map((item) => SupportMessageModel.fromJson(item)).toList();
        // حفظ الرسائل محلياً
        _cacheMessagesLocally(ticketId, messages);
        return messages;
      }
    } catch (e) {
      debugPrint('[SupportService] Error fetching ticket messages: $e');
    }
    // الرجوع للنسخة المخزنة محلياً عند انقطاع الاتصال
    return _getCachedMessages(ticketId);
  }

  /// إرسال رسالة في التذكرة
  static Future<SupportMessageModel?> sendMessage({
    required String ticketId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.sendTicketMessage(ticketId));
      final body = jsonEncode({
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': 'customer',
        'text': text,
      });

      final response = await http
          .post(url, headers: ApiConfig.authHeaders, body: body)
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return SupportMessageModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('[SupportService] Error sending message: $e');
    }
    return null;
  }

  // التخزين المحلي للتذكرة النشطة
  static void saveActiveTicketId(String ticketId) {
    SecureStorageService.setString(_activeTicketStorageKey, ticketId);
  }

  static String? getActiveTicketId() {
    return SecureStorageService.getString(_activeTicketStorageKey);
  }

  static void clearActiveTicket() {
    SecureStorageService.remove(_activeTicketStorageKey);
  }

  static void _cacheMessagesLocally(String ticketId, List<SupportMessageModel> msgs) {
    try {
      final raw = jsonEncode(msgs.map((m) => m.toJson()).toList());
      SecureStorageService.setString(_ticketMessagesKey(ticketId), raw);
    } catch (_) {}
  }

  static List<SupportMessageModel> _getCachedMessages(String ticketId) {
    try {
      final raw = SecureStorageService.getString(_ticketMessagesKey(ticketId));
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        return decoded.map((item) => SupportMessageModel.fromJson(item)).toList();
      }
    } catch (_) {}
    return [];
  }
}
