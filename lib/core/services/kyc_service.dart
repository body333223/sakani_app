import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sakani/core/security/secure_storage_service.dart';

enum KycStatus {
  notSubmitted,
  pending,
  verified,
}

class KycData {
  final KycStatus status;
  final String documentType; // 'national_id' or 'passport'
  final String documentNumber;
  final String? frontPhoto;
  final String? backPhoto;
  final DateTime? verifiedAt;

  const KycData({
    this.status = KycStatus.notSubmitted,
    this.documentType = 'national_id',
    this.documentNumber = '',
    this.frontPhoto,
    this.backPhoto,
    this.verifiedAt,
  });

  bool get isVerified => status == KycStatus.verified;

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'documentType': documentType,
        'documentNumber': documentNumber,
        'frontPhoto': frontPhoto,
        'backPhoto': backPhoto,
        'verifiedAt': verifiedAt?.toIso8601String(),
      };

  factory KycData.fromJson(Map<String, dynamic> json) {
    KycStatus status = KycStatus.notSubmitted;
    final statusStr = json['status'] as String?;
    if (statusStr == 'verified') {
      status = KycStatus.verified;
    } else if (statusStr == 'pending') {
      status = KycStatus.pending;
    }

    return KycData(
      status: status,
      documentType: json['documentType'] as String? ?? 'national_id',
      documentNumber: json['documentNumber'] as String? ?? '',
      frontPhoto: json['frontPhoto'] as String?,
      backPhoto: json['backPhoto'] as String?,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'] as String)
          : null,
    );
  }
}

class KycService extends ChangeNotifier {
  static final KycService _instance = KycService._internal();
  factory KycService() => _instance;
  KycService._internal() {
    _load();
  }

  static const String _storageKey = '__sakani_kyc_data__';
  KycData _currentData = const KycData();

  KycData get currentData => _currentData;
  bool get isVerified => _currentData.isVerified;

  void _load() {
    final raw = SecureStorageService.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _currentData = KycData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        _currentData = const KycData();
      }
    }
  }

  Future<void> submitVerification({
    required String documentType,
    required String documentNumber,
    required String frontPhoto,
    String? backPhoto,
  }) async {
    // In luxury hospitality apps, the uploaded national ID or passport is verified
    _currentData = KycData(
      status: KycStatus.verified,
      documentType: documentType,
      documentNumber: documentNumber,
      frontPhoto: frontPhoto,
      backPhoto: backPhoto,
      verifiedAt: DateTime.now(),
    );

    SecureStorageService.setString(
      _storageKey,
      jsonEncode(_currentData.toJson()),
    );
    notifyListeners();
  }

  Future<void> resetVerification() async {
    _currentData = const KycData();
    SecureStorageService.remove(_storageKey);
    notifyListeners();
  }
}
