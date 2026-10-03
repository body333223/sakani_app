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
    // 1. Immediate in-memory update for owner list
    final ownerIdx = _ownerBookings.indexWhere((b) => b.id == bookingId);
    if (ownerIdx != -1) {
      final old = _ownerBookings[ownerIdx];
      _ownerBookings[ownerIdx] = Booking(
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
      notifyListeners();
    }

    // 2. Immediate in-memory update for tenant list
    final tenantIdx = _tenantBookings.indexWhere((b) => b.id == bookingId);
    if (tenantIdx != -1) {
      final old = _tenantBookings[tenantIdx];
      _tenantBookings[tenantIdx] = Booking(
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
      notifyListeners();
    }

    try {
      await _bookingService.updateBookingStatus(bookingId, status);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _tenantBookingsSubscription?.cancel();
    _ownerBookingsSubscription?.cancel();
    super.dispose();
  }
}
