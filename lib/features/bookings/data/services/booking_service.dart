import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../../core/config/constants.dart';
import '../models/booking_model.dart';

/// خدمة إدارة الحجوزات والعمليات المالية (Clean Code Architecture)
class BookingService {
  // التخزين المؤقت يبدأ نظيفاً بدون أي حجوزات وهمية
  static final List<Booking> _cachedBookings = [];
  static final StreamController<List<Booking>> _bookingsStreamController =
      StreamController<List<Booking>>.broadcast();

  void _updateStreams() {
    _bookingsStreamController.add(List.unmodifiable(_cachedBookings));
  }

  /// إنشاء حجز جديد
  Future<String> createBooking(Booking booking) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.bookings),
            headers: ApiConfig.authHeaders,
            body: jsonEncode(booking.toMap()),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final created = Booking.fromMap(data, data['id'] ?? booking.id);
        _cachedBookings.insert(0, created);
        _updateStreams();
        return created.id;
      }
    } catch (_) {}

    final newBooking = Booking(
      id: 'book_${DateTime.now().millisecondsSinceEpoch}',
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
      status: booking.status,
      guests: booking.guests,
      createdAt: booking.createdAt,
    );
    _cachedBookings.insert(0, newBooking);
    _updateStreams();
    return newBooking.id;
  }

  /// جلب حجوزات المستأجر
  Stream<List<Booking>> getTenantBookings(String tenantId) {
    if (tenantId.isNotEmpty) {
      _fetchTenantBookingsFromApi(tenantId);
    }
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
    if (ownerId.isNotEmpty) {
      _fetchOwnerBookingsFromApi(ownerId);
    }
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

  /// تحديث حالة الحجز (قبول / رفض / إلغاء / اكتمال)
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await http
          .patch(
            Uri.parse(ApiConfig.updateBookingStatus(bookingId)),
            headers: ApiConfig.authHeaders,
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {}

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