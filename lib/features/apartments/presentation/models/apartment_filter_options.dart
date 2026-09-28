import 'package:equatable/equatable.dart';

class ApartmentFilterOptions extends Equatable {
  final double minPrice;
  final double maxPrice;
  final String rentType;
  final int minBedrooms;
  final List<String> amenities;
  final String sortBy;

  const ApartmentFilterOptions({
    this.minPrice = 0,
    this.maxPrice = 25000,
    this.rentType = 'الكل',
    this.minBedrooms = 0,
    this.amenities = const [],
    this.sortBy = 'newest',
  });

  bool get hasActiveFilters =>
      minPrice > 0 ||
      maxPrice < 25000 ||
      rentType != 'الكل' ||
      minBedrooms > 0 ||
      amenities.isNotEmpty ||
      sortBy != 'newest';

  int get activeFiltersCount {
    int count = 0;
    if (minPrice > 0) count++;
    if (maxPrice < 25000) count++;
    if (rentType != 'الكل') count++;
    if (minBedrooms > 0) count++;
    count += amenities.length;
    if (sortBy != 'newest') count++;
    return count;
  }

  ApartmentFilterOptions copyWith({
    double? minPrice,
    double? maxPrice,
    String? rentType,
    int? minBedrooms,
    List<String>? amenities,
    String? sortBy,
  }) {
    return ApartmentFilterOptions(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      rentType: rentType ?? this.rentType,
      minBedrooms: minBedrooms ?? this.minBedrooms,
      amenities: amenities ?? this.amenities,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [
        minPrice,
        maxPrice,
        rentType,
        minBedrooms,
        amenities,
        sortBy,
      ];
}
