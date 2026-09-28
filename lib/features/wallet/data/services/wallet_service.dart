import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sakani/core/security/secure_storage_service.dart';

class WalletTransaction {
  final String id;
  final String title;
  final String description;
  final double amount;
  final bool isCredit; // true = added to wallet, false = spent/deducted
  final String method; // 'InstaPay', 'Vodafone Cash', 'Visa', 'Booking Payment'
  final DateTime date;

  const WalletTransaction({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.isCredit,
    required this.method,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'amount': amount,
        'isCredit': isCredit,
        'method': method,
        'date': date.toIso8601String(),
      };

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      WalletTransaction(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        amount: (json['amount'] as num).toDouble(),
        isCredit: json['isCredit'] as bool,
        method: json['method'] as String,
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
  static const String _txKey = '__sakani_wallet_txs__';

  double _balance = 2500.0; // Welcome initial balance
  List<WalletTransaction> _transactions = [];

  double get balance => _balance;
  List<WalletTransaction> get transactions => List.unmodifiable(_transactions);

  void _load() {
    final rawBal = SecureStorageService.getString(_balanceKey);
    if (rawBal != null && rawBal.isNotEmpty) {
      _balance = double.tryParse(rawBal) ?? 2500.0;
    } else {
      _balance = 2500.0;
    }

    final rawTxs = SecureStorageService.getString(_txKey);
    if (rawTxs != null && rawTxs.isNotEmpty) {
      try {
        final list = jsonDecode(rawTxs) as List;
        _transactions = list
            .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _transactions = _defaultTransactions();
      }
    } else {
      _transactions = _defaultTransactions();
      _save();
    }
  }

  List<WalletTransaction> _defaultTransactions() {
    return [
      WalletTransaction(
        id: 'tx_init_1',
        title: 'مكافأة ترحيبية في المحفظة',
        description: 'رصيد ترحيبي مهدى من تطبيق سكني',
        amount: 2500.0,
        isCredit: true,
        method: 'هدية سكني',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  Future<void> topUp({
    required double amount,
    required String method,
  }) async {
    _balance += amount;
    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: 'شحن رصيد بالمحفظة',
      description: 'تم الشحن بنجاح عبر $method',
      amount: amount,
      isCredit: true,
      method: method,
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
  }) async {
    if (_balance < amount) return false;
    _balance -= amount;
    final tx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      amount: amount,
      isCredit: false,
      method: 'رصيد المحفظة',
      date: DateTime.now(),
    );
    _transactions.insert(0, tx);
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> _save() async {
    SecureStorageService.setString(_balanceKey, _balance.toString());
    final txListJson = jsonEncode(_transactions.map((t) => t.toJson()).toList());
    SecureStorageService.setString(_txKey, txListJson);
  }
}
