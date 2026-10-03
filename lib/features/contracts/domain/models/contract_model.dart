import 'dart:convert';
import 'package:crypto/crypto.dart';

/// نموذج العقد الإلكتروني الموثق رسمياً (Digital Rental Contract)
class ContractModel {
  final String id; // رقم العقد الرسمي مثل SKN-EGY-2026-XXXX
  final String bookingId;
  final String apartmentId;
  final String apartmentTitle;
  final String apartmentAddress;
  final String apartmentCity;
  
  // بيانات المؤجر (المالك)
  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final String ownerNationalId;

  // بيانات المستأجر
  final String tenantId;
  final String tenantName;
  final String tenantPhone;
  final String tenantNationalId;

  // بيانات الإيجار المالية والزمنية
  final DateTime startDate;
  final DateTime endDate;
  final String periodType;
  final double totalRent;
  final double securityDeposit;

  // التوثيق الرقمي والأمان
  final String digitalHash; // البصمة الرقمية المشفرة SHA-256
  final String qrData;
  final DateTime createdAt;
  final bool isOwnerSigned;
  final bool isTenantSigned;
  final String status; // 'معتمد وموثق قانونياً', 'ساري', 'منتهي'

  ContractModel({
    required this.id,
    required this.bookingId,
    required this.apartmentId,
    required this.apartmentTitle,
    required this.apartmentAddress,
    required this.apartmentCity,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerNationalId,
    required this.tenantId,
    required this.tenantName,
    required this.tenantPhone,
    required this.tenantNationalId,
    required this.startDate,
    required this.endDate,
    required this.periodType,
    required this.totalRent,
    required this.securityDeposit,
    required this.digitalHash,
    required this.qrData,
    DateTime? createdAt,
    this.isOwnerSigned = true,
    this.isTenantSigned = true,
    this.status = 'معتمد وموثق قانونياً',
  }) : createdAt = createdAt ?? DateTime.now();

  /// توليد البصمة الرقمية المشفرة للعقد (SHA-256 Cryptographic Hash)
  static String generateDigitalHash({
    required String contractId,
    required String ownerNationalId,
    required String tenantNationalId,
    required String apartmentId,
    required double totalRent,
    required DateTime timestamp,
  }) {
    final rawData = '$contractId:$ownerNationalId:$tenantNationalId:$apartmentId:$totalRent:${timestamp.millisecondsSinceEpoch}:sakani_escrow_legal_key';
    final bytes = utf8.encode(rawData);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'apartmentId': apartmentId,
      'apartmentTitle': apartmentTitle,
      'apartmentAddress': apartmentAddress,
      'apartmentCity': apartmentCity,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'ownerNationalId': ownerNationalId,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'tenantPhone': tenantPhone,
      'tenantNationalId': tenantNationalId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'periodType': periodType,
      'totalRent': totalRent,
      'securityDeposit': securityDeposit,
      'digitalHash': digitalHash,
      'qrData': qrData,
      'createdAt': createdAt.toIso8601String(),
      'isOwnerSigned': isOwnerSigned,
      'isTenantSigned': isTenantSigned,
      'status': status,
    };
  }

  factory ContractModel.fromMap(Map<String, dynamic> map) {
    return ContractModel(
      id: map['id'] ?? '',
      bookingId: map['bookingId'] ?? '',
      apartmentId: map['apartmentId'] ?? '',
      apartmentTitle: map['apartmentTitle'] ?? '',
      apartmentAddress: map['apartmentAddress'] ?? '',
      apartmentCity: map['apartmentCity'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerPhone: map['ownerPhone'] ?? '',
      ownerNationalId: map['ownerNationalId'] ?? '',
      tenantId: map['tenantId'] ?? '',
      tenantName: map['tenantName'] ?? '',
      tenantPhone: map['tenantPhone'] ?? '',
      tenantNationalId: map['tenantNationalId'] ?? '',
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now(),
      periodType: map['periodType'] ?? 'شهري',
      totalRent: (map['totalRent'] ?? 0.0).toDouble(),
      securityDeposit: (map['securityDeposit'] ?? 0.0).toDouble(),
      digitalHash: map['digitalHash'] ?? '',
      qrData: map['qrData'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      isOwnerSigned: map['isOwnerSigned'] ?? true,
      isTenantSigned: map['isTenantSigned'] ?? true,
      status: map['status'] ?? 'معتمد وموثق قانونياً',
    );
  }
}
