import 'package:sakani/features/bookings/domain/entities/booking_entity.dart';
import 'package:sakani/features/bookings/domain/repositories/booking_repository.dart';

class GetOwnerBookingsUseCase {
  final BookingRepository repository;

  GetOwnerBookingsUseCase(this.repository);

  Stream<List<BookingEntity>> call(String ownerId) {
    return repository.getOwnerBookings(ownerId);
  }
}
