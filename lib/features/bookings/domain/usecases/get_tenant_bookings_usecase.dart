import 'package:sakani/features/bookings/domain/entities/booking_entity.dart';
import 'package:sakani/features/bookings/domain/repositories/booking_repository.dart';

class GetTenantBookingsUseCase {
  final BookingRepository repository;

  GetTenantBookingsUseCase(this.repository);

  Stream<List<BookingEntity>> call(String tenantId) {
    return repository.getTenantBookings(tenantId);
  }
}
