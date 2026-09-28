import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sakani/features/bookings/data/models/booking_model.dart';
import 'package:sakani/features/bookings/data/services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();
  List<Booking> _tenantBookings = [];
  List<Booking> _ownerBookings = [];
  bool _isLoading = false;
  String? _error;

  List<Booking> get tenantBookings => _tenantBookings;
  List<Booking> get ownerBookings => _ownerBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  StreamSubscription<List<Booking>>? _tenantBookingsSubscription;
  StreamSubscription<List<Booking>>? _ownerBookingsSubscription;

  Future<void> getTenantBookings(String tenantId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _tenantBookingsSubscription?.cancel();
      _tenantBookingsSubscription = _bookingService.getTenantBookings(tenantId).listen(
        (list) {
          _tenantBookings = list;
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          _error = e.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getOwnerBookings(String ownerId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _ownerBookingsSubscription?.cancel();
      _ownerBookingsSubscription = _bookingService.getOwnerBookings(ownerId).listen(
        (list) {
          _ownerBookings = list;
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          _error = e.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBooking(Booking booking) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _bookingService.createBooking(booking);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _bookingService.updateBookingStatus(bookingId, status);
    } catch (e) {
      _error = e.toString();
    }
  }

  @override
  void dispose() {
    _tenantBookingsSubscription?.cancel();
    _ownerBookingsSubscription?.cancel();
    super.dispose();
  }
}
