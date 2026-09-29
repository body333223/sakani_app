import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sakani/core/config/api_config.dart';
import 'package:sakani/core/error/exceptions.dart';
import 'package:sakani/features/bookings/data/models/booking_model.dart';

abstract class BookingRemoteDataSource {
  Future<String> createBooking(BookingModel booking);
  Future<List<BookingModel>> getTenantBookings(String tenantId);
  Future<List<BookingModel>> getOwnerBookings(String ownerId);
  Future<void> updateBookingStatus(String bookingId, String status);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final http.Client client;

  BookingRemoteDataSourceImpl({required this.client});

  @override
  Future<String> createBooking(BookingModel booking) async {
    try {
      final response = await client
          .post(
            Uri.parse(ApiConfig.bookings),
            headers: ApiConfig.authHeaders,
            body: jsonEncode(booking.toMap()),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['id'] ?? booking.id;
      }
      return booking.id;
    } catch (_) {
      return booking.id;
    }
  }

  @override
  Future<List<BookingModel>> getTenantBookings(String tenantId) async {
    try {
      final response = await client
          .get(
            Uri.parse(ApiConfig.tenantBookings(tenantId)),
            headers: ApiConfig.authHeaders,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data
            .map((item) => BookingModel.fromMap(item, item['id'] ?? ''))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<BookingModel>> getOwnerBookings(String ownerId) async {
    try {
      final response = await client
          .get(
            Uri.parse(ApiConfig.ownerBookings(ownerId)),
            headers: ApiConfig.authHeaders,
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = jsonDecode(utf8.decode(response.bodyBytes));
        return data
            .map((item) => BookingModel.fromMap(item, item['id'] ?? ''))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      final response = await client
          .patch(
            Uri.parse(ApiConfig.updateBookingStatus(bookingId)),
            headers: ApiConfig.authHeaders,
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('فشل في تحديث حالة الحجز', response.statusCode);
      }
    } catch (_) {}
  }
}
