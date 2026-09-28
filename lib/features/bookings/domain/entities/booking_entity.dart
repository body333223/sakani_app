import 'package:equatable/equatable.dart';

class BookingEntity extends Equatable {
  final String id;
  final String apartmentId;
  final String tenantId;
  final String ownerId;
  final String tenantName;
  final String apartmentTitle;
  final DateTime startDate;
  final DateTime endDate;
  final String periodType; // 'يومي', 'شهري', 'سنوي'
  final double totalAmount;
  final double commissionAmount;
  final double securityDeposit;
  final String status; // 'قيد الانتظار', 'مقبول', 'مرفوض', 'نشط', 'منتهي', 'ملغي'
  final int guests;
  final DateTime createdAt;

  BookingEntity({
    required this.id,
    required this.apartmentId,
    required this.tenantId,
    required this.ownerId,
    required this.tenantName,
    required this.apartmentTitle,
    required this.startDate,
    required this.endDate,
    required this.periodType,
    required this.totalAmount,
    required this.commissionAmount,
    required this.securityDeposit,
    this.status = 'قيد الانتظار',
    this.guests = 1,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get ownerEarnings => totalAmount - commissionAmount;

  @override
  List<Object?> get props => [
        id,
        apartmentId,
        tenantId,
        ownerId,
        tenantName,
        apartmentTitle,
        startDate,
        endDate,
        periodType,
        totalAmount,
        commissionAmount,
        securityDeposit,
        status,
        guests,
        createdAt,
      ];
}
