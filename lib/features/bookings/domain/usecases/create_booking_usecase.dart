import 'package:sakani/core/usecase/usecase.dart';
import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/bookings/domain/entities/booking_entity.dart';
import 'package:sakani/features/bookings/domain/repositories/booking_repository.dart';

class CreateBookingUseCase implements UseCase<String, BookingEntity> {
  final BookingRepository repository;

  CreateBookingUseCase(this.repository);

  @override
  Future<Result<String>> call(BookingEntity params) {
    return repository.createBooking(params);
  }
}
