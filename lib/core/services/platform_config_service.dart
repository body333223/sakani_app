import 'package:flutter/foundation.dart';
import 'package:sakani/core/security/secure_storage_service.dart';

/// خدمة إدارة إعدادات المنصة وعمولة المدير العام الديناميكية
class PlatformConfigService extends ChangeNotifier {
  static final PlatformConfigService _instance = PlatformConfigService._internal();
  factory PlatformConfigService() => _instance;
  PlatformConfigService._internal() {
    _loadConfig();
  }

  static const String _commissionKey = '__sakani_platform_commission_rate__';

  double _commissionRate = 0.10; // Default 10%
  final double _vatRate = 0.14;  // Default 14% VAT

  double get commissionRate => _commissionRate;
  double get commissionPercentage => _commissionRate * 100.0;
  double get vatRate => _vatRate;

  void _loadConfig() {
    final savedCommission = SecureStorageService.getString(_commissionKey);
    if (savedCommission != null && savedCommission.isNotEmpty) {
      _commissionRate = double.tryParse(savedCommission) ?? 0.10;
    }
  }

  /// تحديث نسبة عمولة المنصة بواسطة المدير العام
  Future<void> setCommissionPercentage(double percentage) async {
    if (percentage < 1.0) percentage = 1.0;
    if (percentage > 30.0) percentage = 30.0;
    _commissionRate = percentage / 100.0;
    SecureStorageService.setString(_commissionKey, _commissionRate.toString());
    notifyListeners();
  }

  /// حساب عمولة المنصة لمبلغ معين
  double calculateCommission(double amount) {
    return amount * _commissionRate;
  }
}
