import 'package:equatable/equatable.dart';
import 'package:sakani/features/bookings/domain/entities/booking_entity.dart';

class BookingState extends Equatable {
  final bool isLoading;
  final List<BookingEntity> tenantBookings;
  final List<BookingEntity> ownerBookings;
  final bool isSubmitting;
  final String? errorMessage;
  final String? successMessage;

  const BookingState({
    this.isLoading = false,
    this.tenantBookings = const [],
    this.ownerBookings = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.successMessage,
  });

  BookingState copyWith({
    bool? isLoading,
    List<BookingEntity>? tenantBookings,
    List<BookingEntity>? ownerBookings,
    bool? isSubmitting,
    String? errorMessage,
    String? successMessage,
  }) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      tenantBookings: tenantBookings ?? this.tenantBookings,
      ownerBookings: ownerBookings ?? this.ownerBookings,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        tenantBookings,
        ownerBookings,
        isSubmitting,
        errorMessage,
        successMessage,
      ];
}
