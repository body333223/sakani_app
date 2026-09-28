import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/bookings/domain/entities/booking_entity.dart';

abstract class BookingRepository {
  Stream<List<BookingEntity>> getTenantBookings(String tenantId);

  Stream<List<BookingEntity>> getOwnerBookings(String ownerId);

  Future<Result<String>> createBooking(BookingEntity booking);

  Future<Result<void>> updateBookingStatus(String bookingId, String status);
}
