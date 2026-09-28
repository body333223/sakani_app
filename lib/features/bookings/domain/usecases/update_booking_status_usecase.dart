import 'package:equatable/equatable.dart';
import 'package:sakani/core/usecase/usecase.dart';
import 'package:sakani/core/utils/result.dart';
import 'package:sakani/features/bookings/domain/repositories/booking_repository.dart';

class UpdateBookingStatusParams extends Equatable {
  final String bookingId;
  final String status;

  const UpdateBookingStatusParams({required this.bookingId, required this.status});

  @override
  List<Object?> get props => [bookingId, status];
}

class UpdateBookingStatusUseCase implements UseCase<void, UpdateBookingStatusParams> {
  final BookingRepository repository;

  UpdateBookingStatusUseCase(this.repository);

  @override
  Future<Result<void>> call(UpdateBookingStatusParams params) {
    return repository.updateBookingStatus(params.bookingId, params.status);
  }
}
