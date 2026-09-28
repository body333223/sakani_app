import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakani/features/bookings/domain/entities/booking_entity.dart';
import 'package:sakani/features/bookings/domain/repositories/booking_repository.dart';
import 'package:sakani/features/bookings/domain/usecases/create_booking_usecase.dart';
import 'package:sakani/features/bookings/domain/usecases/get_owner_bookings_usecase.dart';
import 'package:sakani/features/bookings/domain/usecases/get_tenant_bookings_usecase.dart';
import 'package:sakani/features/bookings/domain/usecases/update_booking_status_usecase.dart';
import 'package:sakani/features/bookings/presentation/cubit/booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final GetTenantBookingsUseCase getTenantBookingsUseCase;
  final GetOwnerBookingsUseCase getOwnerBookingsUseCase;
  final CreateBookingUseCase createBookingUseCase;
  final UpdateBookingStatusUseCase updateBookingStatusUseCase;
  final BookingRepository bookingRepository;

  StreamSubscription<List<BookingEntity>>? _tenantSub;
  StreamSubscription<List<BookingEntity>>? _ownerSub;

  BookingCubit({
    required this.getTenantBookingsUseCase,
    required this.getOwnerBookingsUseCase,
    required this.createBookingUseCase,
    required this.updateBookingStatusUseCase,
    required this.bookingRepository,
  }) : super(const BookingState());

  void loadTenantBookings(String tenantId) {
    if (tenantId.isEmpty) return;
    emit(state.copyWith(isLoading: true));
    _tenantSub?.cancel();
    _tenantSub = getTenantBookingsUseCase(tenantId).listen((bookings) {
      emit(state.copyWith(isLoading: false, tenantBookings: bookings));
    });
  }

  void loadOwnerBookings(String ownerId) {
    if (ownerId.isEmpty) return;
    emit(state.copyWith(isLoading: true));
    _ownerSub?.cancel();
    _ownerSub = getOwnerBookingsUseCase(ownerId).listen((bookings) {
      emit(state.copyWith(isLoading: false, ownerBookings: bookings));
    });
  }

  Future<bool> createBooking(BookingEntity booking) async {
    emit(state.copyWith(isSubmitting: true));
    final result = await createBookingUseCase(booking);

    return result.fold(
      (failure) {
        emit(state.copyWith(isSubmitting: false, errorMessage: failure.message));
        return false;
      },
      (id) {
        emit(state.copyWith(
          isSubmitting: false,
          successMessage: 'تم إرسال طلب الحجز بنجاح!',
        ));
        return true;
      },
    );
  }

  Future<void> updateStatus(String bookingId, String status) async {
    await updateBookingStatusUseCase(UpdateBookingStatusParams(
      bookingId: bookingId,
      status: status,
    ));
  }

  @override
  Future<void> close() {
    _tenantSub?.cancel();
    _ownerSub?.cancel();
    return super.close();
  }
}
