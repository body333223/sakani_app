import 'package:equatable/equatable.dart';
import 'package:sakani/features/apartments/domain/entities/apartment_entity.dart';
import 'package:sakani/features/apartments/presentation/models/apartment_filter_options.dart';

class ApartmentState extends Equatable {
  final bool isLoading;
  final List<ApartmentEntity> apartments;
  final List<ApartmentEntity> ownerApartments;
  final String? selectedCity;
  final double? maxPrice;
  final ApartmentFilterOptions filterOptions;
  final String? errorMessage;
  final bool isSubmitting;
  final String? actionSuccess;

  const ApartmentState({
    this.isLoading = false,
    this.apartments = const [],
    this.ownerApartments = const [],
    this.selectedCity,
    this.maxPrice,
    this.filterOptions = const ApartmentFilterOptions(),
    this.errorMessage,
    this.isSubmitting = false,
    this.actionSuccess,
  });

  /// تطبيق الفلاتر والفرز الذكي
  List<ApartmentEntity> get filteredApartments {
    var result = List<ApartmentEntity>.from(apartments);

    // فلترة المدينة
    if (selectedCity != null && selectedCity!.isNotEmpty && selectedCity != 'الكل') {
      result = result.where((a) => a.city == selectedCity).toList();
    }

    // فلترة السعر
    result = result.where((a) {
      return a.monthlyPrice >= filterOptions.minPrice &&
          a.monthlyPrice <= filterOptions.maxPrice;
    }).toList();

    // فلترة نوع الإيجار
    if (filterOptions.rentType != 'الكل') {
      result = result.where((a) {
        return a.availableRentTypes.contains(filterOptions.rentType);
      }).toList();
    }

    // فلترة الغرف
    if (filterOptions.minBedrooms > 0) {
      result = result.where((a) => a.bedrooms >= filterOptions.minBedrooms).toList();
    }

    // فلترة المرافق
    if (filterOptions.amenities.isNotEmpty) {
      result = result.where((a) {
        return filterOptions.amenities.every((amenity) => a.amenities.contains(amenity));
      }).toList();
    }

    // الفرز
    switch (filterOptions.sortBy) {
      case 'price_asc':
        result.sort((a, b) => a.monthlyPrice.compareTo(b.monthlyPrice));
        break;
      case 'price_desc':
        result.sort((a, b) => b.monthlyPrice.compareTo(a.monthlyPrice));
        break;
      case 'area_desc':
        result.sort((a, b) => b.area.compareTo(a.area));
        break;
      case 'newest':
      default:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return result;
  }

  ApartmentState copyWith({
    bool? isLoading,
    List<ApartmentEntity>? apartments,
    List<ApartmentEntity>? ownerApartments,
    String? selectedCity,
    double? maxPrice,
    ApartmentFilterOptions? filterOptions,
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
      filterOptions: filterOptions ?? this.filterOptions,
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
        filterOptions,
        errorMessage,
        isSubmitting,
        actionSuccess,
      ];
}
