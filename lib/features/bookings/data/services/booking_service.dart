import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/config/constants.dart';
import '../models/booking_model.dart';

/// خدمة إدارة الحجوزات والعمليات مع التخزين الدائم (Clean Code Architecture)
class BookingService {
  static const String _storageKey = '__sakani_persistent_bookings_v2__';
  static final List<Booking> _cachedBookings = [];
  static final StreamController<List<Booking>> _bookingsStreamController =
      StreamController<List<Booking>>.broadcast();
  static bool _hasLoadedFromDisk = false;

  BookingService() {
    _ensureLoadedFromDisk();
  }

  static Future<void> _ensureLoadedFromDisk() async {
    if (_hasLoadedFromDisk) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List decoded = jsonDecode(raw);
        _cachedBookings.clear();
        for (var item in decoded) {
          try {
            final b = Booking.fromMap(item, item['id'] ?? '');
            _cachedBookings.add(b);
          } catch (_) {}
        }
        _hasLoadedFromDisk = true;
        _bookingsStreamController.add(List.unmodifiable(_cachedBookings));
      } else {
        _hasLoadedFromDisk = true;
      }
    } catch (_) {
      _hasLoadedFromDisk = true;
    }
  }

  static Future<void> _saveBookingsToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _cachedBookings.map((b) => b.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (_) {}
  }

  void _updateStreams() {
    _bookingsStreamController.add(List.unmodifiable(_cachedBookings));
    _saveBookingsToDisk();
  }

  /// إنشاء حجز جديد مع الحفظ الفوري الدائم
  Future<String> createBooking(Booking booking) async {
    await _ensureLoadedFromDisk();

    // 1. Try sending to the server
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.bookings),
            headers: ApiConfig.authHeaders,
            body: jsonEncode(booking.toMap()),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final created = Booking.fromMap(data, data['id'] ?? booking.id);
        _cachedBookings.removeWhere((b) => b.id == created.id);
        _cachedBookings.insert(0, created);
        _updateStreams();
        return created.id;
      }
    } catch (_) {}

    // 2. Persistent fallback with unique ID
    final newBooking = Booking(
      id: booking.id.isNotEmpty
          ? booking.id
          : 'book_${DateTime.now().millisecondsSinceEpoch}',
      apartmentId: booking.apartmentId,
      apartmentTitle: booking.apartmentTitle,
      tenantId: booking.tenantId,
      tenantName: booking.tenantName,
      ownerId: booking.ownerId,
      startDate: booking.startDate,
      endDate: booking.endDate,
      totalAmount: booking.totalAmount,
      commissionAmount: booking.commissionAmount,
      securityDeposit: booking.securityDeposit,
      periodType: booking.periodType,
      status: 'قيد الانتظار',
      guests: booking.guests,
      createdAt: booking.createdAt,
    );

    _cachedBookings.removeWhere((b) => b.id == newBooking.id);
    _cachedBookings.insert(0, newBooking);
    _updateStreams();
    return newBooking.id;
  }

  /// جلب حجوزات المستأجر
  Stream<List<Booking>> getTenantBookings(String tenantId) {
    _ensureLoadedFromDisk().then((_) {
      if (tenantId.isNotEmpty) {
        _fetchTenantBookingsFromApi(tenantId);
      }
    });

    return Stream<List<Booking>>.multi((controller) {
      final initial = _cachedBookings.where((b) => b.tenantId == tenantId).toList();
      initial.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(initial);

      final subscription = _bookingsStreamController.stream.listen((list) {
        final filtered = list.where((b) => b.tenantId == tenantId).toList();
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        controller.add(filtered);
      });
      controller.onCancel = () => subscription.cancel();
    });
  }

  /// مزامنة حجوزات المستأجر من الخادم
  Future<void> _fetchTenantBookingsFromApi(String tenantId) async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.tenantBookings(tenantId)),
            headers: ApiConfig.authHeaders,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        for (var item in data) {
          final b = Booking.fromMap(item, item['id'] ?? '');
          final idx = _cachedBookings.indexWhere((x) => x.id == b.id);
          if (idx != -1) {
            _cachedBookings[idx] = b;
          } else {
            _cachedBookings.add(b);
          }
        }
        _updateStreams();
      }
    } catch (_) {}
  }

  /// جلب حجوزات صاحب العقار
  Stream<List<Booking>> getOwnerBookings(String ownerId) {
    _ensureLoadedFromDisk().then((_) {
      if (ownerId.isNotEmpty) {
        _fetchOwnerBookingsFromApi(ownerId);
      }
    });

    return Stream<List<Booking>>.multi((controller) {
      final initial = _cachedBookings.where((b) => b.ownerId == ownerId).toList();
      initial.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(initial);

      final subscription = _bookingsStreamController.stream.listen((list) {
        final filtered = list.where((b) => b.ownerId == ownerId).toList();
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        controller.add(filtered);
      });
      controller.onCancel = () => subscription.cancel();
    });
  }

  /// مزامنة حجوزات المالك من الخادم
  Future<void> _fetchOwnerBookingsFromApi(String ownerId) async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.ownerBookings(ownerId)),
            headers: ApiConfig.authHeaders,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        for (var item in data) {
          final b = Booking.fromMap(item, item['id'] ?? '');
          final idx = _cachedBookings.indexWhere((x) => x.id == b.id);
          if (idx != -1) {
            _cachedBookings[idx] = b;
          } else {
            _cachedBookings.add(b);
          }
        }
        _updateStreams();
      }
    } catch (_) {}
  }

  /// تحديث حالة الحجز بواسطة المالك (مقبول / مرفوض / منتهي)
  Future<void> updateBookingStatus(String bookingId, String status) async {
    await _ensureLoadedFromDisk();

    // 1. Notify Backend API
    try {
      await http
          .patch(
            Uri.parse(ApiConfig.updateBookingStatus(bookingId)),
            headers: ApiConfig.authHeaders,
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {}

    // 2. Update local state immediately
    final index = _cachedBookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final old = _cachedBookings[index];
      _cachedBookings[index] = Booking(
        id: old.id,
        apartmentId: old.apartmentId,
        apartmentTitle: old.apartmentTitle,
        tenantId: old.tenantId,
        tenantName: old.tenantName,
        ownerId: old.ownerId,
        startDate: old.startDate,
        endDate: old.endDate,
        totalAmount: old.totalAmount,
        commissionAmount: old.commissionAmount,
        securityDeposit: old.securityDeposit,
        periodType: old.periodType,
        status: status,
        guests: old.guests,
        createdAt: old.createdAt,
      );
      _updateStreams();
    }
  }

  /// حساب عمولة المنصة
  static double calculateCommission(double totalAmount) {
    return totalAmount * AppConstants.commissionRate;
  }

  /// حساب الإجمالي المطلوب دفعه شامل التأمين
  static double calculateTotalAmount({
    required double pricePerUnit,
    required int quantity,
    required double securityDeposit,
  }) {
    return (pricePerUnit * quantity) + securityDeposit;
  }
}