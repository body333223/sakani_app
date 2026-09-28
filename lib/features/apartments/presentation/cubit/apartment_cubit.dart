import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakani/features/apartments/domain/entities/apartment_entity.dart';
import 'package:sakani/features/apartments/domain/repositories/apartment_repository.dart';
import 'package:sakani/features/apartments/domain/usecases/add_apartment_usecase.dart';
import 'package:sakani/features/apartments/domain/usecases/delete_apartment_usecase.dart';
import 'package:sakani/features/apartments/domain/usecases/get_apartments_usecase.dart';
import 'package:sakani/features/apartments/domain/usecases/get_owner_apartments_usecase.dart';
import 'package:sakani/features/apartments/domain/usecases/update_apartment_usecase.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_state.dart';
import 'package:sakani/features/apartments/presentation/models/apartment_filter_options.dart';

class ApartmentCubit extends Cubit<ApartmentState> {
  final GetApartmentsUseCase getApartmentsUseCase;
  final GetOwnerApartmentsUseCase getOwnerApartmentsUseCase;
  final AddApartmentUseCase addApartmentUseCase;
  final UpdateApartmentUseCase updateApartmentUseCase;
  final DeleteApartmentUseCase deleteApartmentUseCase;
  final ApartmentRepository apartmentRepository;

  StreamSubscription<List<ApartmentEntity>>? _apartmentsSubscription;
  StreamSubscription<List<ApartmentEntity>>? _ownerApartmentsSubscription;

  ApartmentCubit({
    required this.getApartmentsUseCase,
    required this.getOwnerApartmentsUseCase,
    required this.addApartmentUseCase,
    required this.updateApartmentUseCase,
    required this.deleteApartmentUseCase,
    required this.apartmentRepository,
  }) : super(const ApartmentState()) {
    loadApartments();
  }

  void loadApartments({String? city, double? maxPrice}) {
    emit(state.copyWith(isLoading: true, selectedCity: city, maxPrice: maxPrice));

    _apartmentsSubscription?.cancel();
    _apartmentsSubscription = getApartmentsUseCase(
      GetApartmentsParams(city: city, maxPrice: maxPrice),
    ).listen((apartments) {
      emit(state.copyWith(isLoading: false, apartments: apartments));
    });
  }

  void setFilter({String? city, double? maxPrice}) {
    loadApartments(city: city, maxPrice: maxPrice);
  }

  void applyFilters(ApartmentFilterOptions filters) {
    emit(state.copyWith(filterOptions: filters));
  }

  void setSortBy(String sortBy) {
    emit(state.copyWith(
      filterOptions: state.filterOptions.copyWith(sortBy: sortBy),
    ));
  }

  void resetFilters() {
    emit(state.copyWith(
      filterOptions: const ApartmentFilterOptions(),
      selectedCity: null,
    ));
  }

  void loadOwnerApartments(String ownerId) {
    if (ownerId.isEmpty) return;
    _ownerApartmentsSubscription?.cancel();
    _ownerApartmentsSubscription = getOwnerApartmentsUseCase(ownerId).listen((ownerApartments) {
      emit(state.copyWith(ownerApartments: ownerApartments));
    });
  }

  Future<bool> addApartment(ApartmentEntity apartment) async {
    emit(state.copyWith(isSubmitting: true));
    final result = await addApartmentUseCase(apartment);

    return result.fold(
      (failure) {
        emit(state.copyWith(isSubmitting: false, errorMessage: failure.message));
        return false;
      },
      (id) {
        emit(state.copyWith(
          isSubmitting: false,
          actionSuccess: 'تمت إضافة العقار بنجاح',
        ));
        return true;
      },
    );
  }

  Future<void> toggleAvailability(String id, bool currentStatus) async {
    await updateApartmentUseCase(UpdateApartmentParams(
      id: id,
      data: {'isAvailable': !currentStatus},
    ));
  }

  Future<bool> deleteApartment(String id) async {
    final result = await deleteApartmentUseCase(id);
    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
      (_) {
        emit(state.copyWith(actionSuccess: 'تم حذف العقار'));
        return true;
      },
    );
  }

  @override
  Future<void> close() {
    _apartmentsSubscription?.cancel();
    _ownerApartmentsSubscription?.cancel();
    return super.close();
  }
}
