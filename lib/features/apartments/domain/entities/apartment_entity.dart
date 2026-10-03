import 'package:equatable/equatable.dart';

class ApartmentEntity extends Equatable {
  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String description;
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final List<String> amenities;
  final List<String> images;
  final List<String> availableRentTypes;
  final double dailyPrice;
  final double monthlyPrice;
  final double yearlyPrice;
  final double securityDeposit;
  final String contactPhone;
  final String cancellationPolicy;
  final int maxGuests;
  final bool isAvailable;
  final DateTime? occupiedFrom;
  final DateTime? occupiedUntil;
  final DateTime createdAt;

  ApartmentEntity({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.city,
    required this.address,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.bedrooms = 1,
    this.bathrooms = 1,
    this.area = 0.0,
    this.amenities = const [],
    this.images = const [],
    this.availableRentTypes = const ['شهري'],
    this.dailyPrice = 0.0,
    this.monthlyPrice = 0.0,
    this.yearlyPrice = 0.0,
    this.securityDeposit = 0.0,
    this.contactPhone = '',
    this.cancellationPolicy = 'مرنة',
    this.maxGuests = 2,
    this.isAvailable = true,
    this.occupiedFrom,
    this.occupiedUntil,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCurrentlyOccupied =>
      occupiedUntil != null && occupiedUntil!.isAfter(DateTime.now());

  double get pricePerDay => dailyPrice;
  double get pricePerMonth => monthlyPrice > 0 ? monthlyPrice : dailyPrice * 30;
  double get pricePerYear => yearlyPrice > 0 ? yearlyPrice : monthlyPrice * 12;

  @override
  List<Object?> get props => [
        id,
        ownerId,
        ownerName,
        title,
        description,
        city,
        address,
        latitude,
        longitude,
        bedrooms,
        bathrooms,
        area,
        amenities,
        images,
        availableRentTypes,
        dailyPrice,
        monthlyPrice,
        yearlyPrice,
        securityDeposit,
        contactPhone,
        cancellationPolicy,
        maxGuests,
        isAvailable,
        createdAt,
      ];
}
