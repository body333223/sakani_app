import 'package:sakani/features/bookings/domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  BookingModel({
    required super.id,
    required super.apartmentId,
    required super.tenantId,
    required super.ownerId,
    required super.tenantName,
    required super.apartmentTitle,
    required super.startDate,
    required super.endDate,
    required super.periodType,
    required super.totalAmount,
    required super.commissionAmount,
    required super.securityDeposit,
    super.status = 'قيد الانتظار',
    super.guests = 1,
    super.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'apartmentId': apartmentId,
      'tenantId': tenantId,
      'ownerId': ownerId,
      'tenantName': tenantName,
      'apartmentTitle': apartmentTitle,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'periodType': periodType,
      'totalAmount': totalAmount,
      'commissionAmount': commissionAmount,
      'securityDeposit': securityDeposit,
      'status': status,
      'guests': guests,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      apartmentId: map['apartmentId'] ?? '',
      tenantId: map['tenantId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      tenantName: map['tenantName'] ?? '',
      apartmentTitle: map['apartmentTitle'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      periodType: map['periodType'] ?? 'شهري',
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      commissionAmount: (map['commissionAmount'] ?? 0.0).toDouble(),
      securityDeposit: (map['securityDeposit'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'قيد الانتظار',
      guests: map['guests'] ?? 1,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  factory BookingModel.fromEntity(BookingEntity entity) {
    return BookingModel(
      id: entity.id,
      apartmentId: entity.apartmentId,
      tenantId: entity.tenantId,
      ownerId: entity.ownerId,
      tenantName: entity.tenantName,
      apartmentTitle: entity.apartmentTitle,
      startDate: entity.startDate,
      endDate: entity.endDate,
      periodType: entity.periodType,
      totalAmount: entity.totalAmount,
      commissionAmount: entity.commissionAmount,
      securityDeposit: entity.securityDeposit,
      status: entity.status,
      guests: entity.guests,
      createdAt: entity.createdAt,
    );
  }
}

/// Backwards compatibility alias
typedef Booking = BookingModel;
