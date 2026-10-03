import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sakani/core/security/secure_storage_service.dart';

class WalletTransaction {
  final String id;
  final String referenceCode;
  final String title;
  final String description;
  final double amount;
  final bool isCredit; // true = added to wallet, false = spent/deducted
  final String method; // 'InstaPay', 'Vodafone Cash', 'Bank Transfer', 'Visa', 'Rental Earnings'
  final String category; // 'topup', 'withdrawal', 'earnings', 'rent_payment', 'escrow'
  final DateTime date;

  const WalletTransaction({
    required this.id,
    required this.referenceCode,
    required this.title,
    required this.description,
    required this.amount,
    required this.isCredit,
    required this.method,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'referenceCode': referenceCode,
        'title': title,
        'description': description,
        'amount': amount,
        'isCredit': isCredit,
        'method': method,
        'category': category,
        'date': date.toIso8601String(),
      };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: json['id'] as String,
        referenceCode: json['referenceCode'] as String? ?? 'SKN-${json['id']}',
        title: json['title'] as String,
        description: json['description'] as String,
        amount: (json['amount'] as num).toDouble(),
        isCredit: json['isCredit'] as bool,
        method: json['method'] as String,
        category: json['category'] as String? ?? (json['isCredit'] as bool ? 'topup' : 'withdrawal'),
        date: DateTime.parse(json['date'] as String),
      );
}

class WalletService extends ChangeNotifier {
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal() {
    _load();
  }

  static const String _balanceKey = '__sakani_wallet_balance__';
  static const String _pendingKey = '__sakani_wallet_pending__';
  static const String _txKey = '__sakani_wallet_txs__';

  double _balance = 0.0;
  double _pendingBalance = 0.0;
  List<WalletTransaction> _transactions = [];

  double get balance => _balance;
  double get pendingBalance => _pendingBalance;
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);

  void _load() {
    final rawBal = SecureStorageService.getString(_balanceKey);
    if (rawBal != null && rawBal.isNotEmpty) {
      _balance = double.tryParse(rawBal) ?? 0.0;
    } else {
      _balance = 0.0;
    }

    final rawPending = SecureStorageService.getString(_pendingKey);
    if (rawPending != null && rawPending.isNotEmpty) {
      _pendingBalance = double.tryParse(rawPending) ?? 0.0;
    } else {
      _pendingBalance = 0.0;
    }

    final rawTxs = SecureStorageService.getString(_txKey);
    if (rawTxs != null && rawTxs.isNotEmpty) {
      try {
        final list = jsonDecode(rawTxs) as List;
        _transactions = list
            .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _transactions = [];
      }
    } else {
      _transactions = [];
    }
  }

  String _generateRef() {
    final now = DateTime.now();
    return 'SKN-${now.year}${(now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0')}';
  }

  Future<void> topUp({
    required double amount,
    required String method,
  }) async {
    _balance += amount;
    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      referenceCode: _generateRef(),
      title: 'شحن رصيد بالمحفظة',
      description: 'تم شحن المحفظة بنجاح عبر $method',
      amount: amount,
      isCredit: true,
      method: method,
      category: 'topup',
      date: DateTime.now(),
    );
    _transactions.insert(0, tx);
    await _save();
    notifyListeners();
  }

  Future<bool> withdraw({
    required double amount,
    required String destination,
    required String accountDetails,
  }) async {
    if (_balance < amount || amount <= 0) return false;
    _balance -= amount;
    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      referenceCode: _generateRef(),
      title: 'سحب أرباح مالية',
      description: 'تم تحويل المبلغ إلى $destination ($accountDetails)',
      amount: amount,
      isCredit: false,
      method: destination,
      category: 'withdrawal',
      date: DateTime.now(),
    );
    _transactions.insert(0, tx);
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> recordBookingEarnings({
    required double amount,
    required String apartmentTitle,
    required String tenantName,
  }) async {
    _balance += amount;
    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      referenceCode: _generateRef(),
      title: 'أرباح تأجير معتمدة',
      description: 'إيراد حجز عقار "$apartmentTitle" من المستأجر $tenantName',
      amount: amount,
      isCredit: true,
      method: 'أرباح إيجار سكني',
      category: 'earnings',
      date: DateTime.now(),
    );
    _transactions.insert(0, tx);
    await _save();
    notifyListeners();
  }

  Future<bool> deduct({
    required double amount,
    required String title,
    required String description,
    String category = 'rent_payment',
  }) async {
    if (_balance < amount) return false;
    _balance -= amount;
    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      referenceCode: _generateRef(),
      title: title,
      description: description,
      amount: amount,
      isCredit: false,
      method: 'رصيد المحفظة',
      category: category,
      date: DateTime.now(),
    );
    _transactions.insert(0, tx);
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> setPendingBalance(double amount) async {
    _pendingBalance = amount;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    SecureStorageService.setString(_balanceKey, _balance.toString());
    SecureStorageService.setString(_pendingKey, _pendingBalance.toString());
    final txListJson = jsonEncode(_transactions.map((t) => t.toJson()).toList());
    SecureStorageService.setString(_txKey, txListJson);
  }
}
