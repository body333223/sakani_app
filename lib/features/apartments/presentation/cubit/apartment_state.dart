import 'package:equatable/equatable.dart';
import 'package:sakani/features/apartments/domain/entities/apartment_entity.dart';

class ApartmentState extends Equatable {
  final bool isLoading;
  final List<ApartmentEntity> apartments;
  final List<ApartmentEntity> ownerApartments;
  final String? selectedCity;
  final double? maxPrice;
  final String? errorMessage;
  final bool isSubmitting;
  final String? actionSuccess;

  const ApartmentState({
    this.isLoading = false,
    this.apartments = const [],
    this.ownerApartments = const [],
    this.selectedCity,
    this.maxPrice,
    this.errorMessage,
    this.isSubmitting = false,
    this.actionSuccess,
  });

  ApartmentState copyWith({
    bool? isLoading,
    List<ApartmentEntity>? apartments,
    List<ApartmentEntity>? ownerApartments,
    String? selectedCity,
    double? maxPrice,
    String? errorMessage,
    bool? isSubmitting,
    String? actionSuccess,
  }) {
    return ApartmentState(
      isLoading: isLoading ?? this.isLoading,
      apartments: apartments ?? this.apartments,
      ownerApartments: ownerApartments ?? this.ownerApartments,
      selectedCity: selectedCity ?? this.selectedCity,
      maxPrice: maxPrice ?? this.maxPrice,
      errorMessage: errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      actionSuccess: actionSuccess,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        apartments,
        ownerApartments,
        selectedCity,
        maxPrice,
        errorMessage,
        isSubmitting,
        actionSuccess,
      ];
}
