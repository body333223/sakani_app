import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/staggered_entrance.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';
import 'package:sakani/features/wallet/data/services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _walletService.addListener(_onWalletChanged);
  }

  @override
  void dispose() {
    _walletService.removeListener(_onWalletChanged);
    super.dispose();
  }

  void _onWalletChanged() {
    if (mounted) setState(() {});
  }

  // ── Top-Up Sheet ──
  void _showTopUpSheet(bool isArabic) {
    final customCtl = TextEditingController(text: '1000');
    double selectedAmount = 1000;
    String selectedMethod = 'InstaPay (إنستاباي)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.accentColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add_card_rounded,
                            color: context.accentColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isArabic ? 'شحن رصيد المحفظة' : 'Top Up Wallet Balance',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isArabic
                        ? 'اختر مبلغ الشحن السريع أو حدد قيمة مخصصة'
                        : 'Select quick amount or specify custom value',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [500.0, 1000.0, 2500.0, 5000.0].map((amt) {
                      final isSel = selectedAmount == amt;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedAmount = amt;
                              customCtl.text = amt.toInt().toString();
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? context.accentColor.withValues(alpha: 0.18)
                                  : context.surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel
                                    ? context.accentColor
                                    : context.borderColor,
                                width: isSel ? 1.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${amt.toInt()} ج.م',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight:
                                      isSel ? FontWeight.w800 : FontWeight.w600,
                                  color: isSel
                                      ? context.accentColor
                                      : context.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: customCtl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: isArabic
                          ? 'المبلغ المطلوب شحنه (ج.م)'
                          : 'Amount to Top Up (EGP)',
                      prefixIcon: Icon(Icons.payments_outlined,
                          color: context.accentColor),
                      suffixText: isArabic ? 'ج.م' : 'EGP',
                      filled: true,
                      fillColor: context.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        setModalState(() => selectedAmount = parsed);
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isArabic ? 'وسيلة الدفع' : 'Payment Method',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentOption(
                    title: isArabic ? 'إنستاباي InstaPay' : 'InstaPay Transfer',
                    subtitle: isArabic
                        ? 'تحويل فوري بدون رسوم إضافية'
                        : 'Instant zero-fee transfer',
                    icon: Icons.flash_on_rounded,
                    color: Colors.purpleAccent,
                    isSelected: selectedMethod.contains('InstaPay'),
                    onTap: () => setModalState(
                        () => selectedMethod = 'InstaPay (إنستاباي)'),
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentOption(
                    title: isArabic
                        ? 'فودافون كاش والمحافظ'
                        : 'Vodafone Cash & Wallets',
                    subtitle: isArabic
                        ? 'الدفع برقم الهاتف الذكي'
                        : 'Pay via mobile phone wallet',
                    icon: Icons.phone_android_rounded,
                    color: Colors.redAccent,
                    isSelected: selectedMethod.contains('فودافون'),
                    onTap: () =>
                        setModalState(() => selectedMethod = 'فودافون كاش'),
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentOption(
                    title: isArabic ? 'بطاقة بنكية' : 'Bank Card (Visa/Master)',
                    subtitle: isArabic
                        ? 'دفع فوري مشفر وآمن'
                        : 'Encrypted online card payment',
                    icon: Icons.credit_card_rounded,
                    color: Colors.blueAccent,
                    isSelected: selectedMethod.contains('بطاقة'),
                    onTap: () =>
                        setModalState(() => selectedMethod = 'بطاقة بنكية'),
                  ),
                  const SizedBox(height: 20),
                  BouncingTap(
                    scaleFactor: 0.96,
                    onTap: () async {
                      if (selectedAmount <= 0) return;
                      final messenger = ScaffoldMessenger.of(context);
                      await _walletService.topUp(
                        amount: selectedAmount,
                        method: selectedMethod,
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isArabic
                                ? 'تم شحن ${selectedAmount.toInt()} ج.م بنجاح إلى محفظتك! 🌟'
                                : 'Successfully topped up ${selectedAmount.toInt()} EGP!',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppGradients.gold,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isArabic
                              ? 'تأكيد وشحن ${selectedAmount.toInt()} ج.م'
                              : 'Confirm & Top Up ${selectedAmount.toInt()} EGP',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Withdrawal Sheet ──
  void _showWithdrawSheet(bool isArabic) {
    final amountCtl = TextEditingController();
    final accountCtl = TextEditingController();
    double selectedAmount = 0;
    String selectedDest = 'حساب بنكي (IBAN)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final balance = _walletService.balance;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.outbox_rounded,
                            color: AppColors.gold, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'سحب الأرباح' : 'Withdraw Earnings',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${isArabic ? "الرصيد المتاح للسحب:" : "Available to withdraw:"} ${balance.toInt()} ج.م',
                            style: TextStyle(
                              color: context.accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountCtl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: isArabic
                          ? 'المبلغ المطلوب سحبه (ج.م)'
                          : 'Amount to withdraw (EGP)',
                      prefixIcon: Icon(Icons.payments_rounded,
                          color: context.accentColor),
                      suffixText: isArabic ? 'ج.م' : 'EGP',
                      filled: true,
                      fillColor: context.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val) ?? 0;
                      setModalState(() => selectedAmount = parsed);
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isArabic ? 'جهة التحويل' : 'Destination',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentOption(
                    title: isArabic
                        ? 'حساب بنكي مصري (IBAN)'
                        : 'Egyptian Bank Account (IBAN)',
                    subtitle: isArabic
                        ? 'تحويل مصرفي معتمد خلال 24 ساعة'
                        : 'Official bank wire within 24 hours',
                    icon: Icons.account_balance_rounded,
                    color: Colors.amberAccent,
                    isSelected: selectedDest.contains('بنكي'),
                    onTap: () => setModalState(
                        () => selectedDest = 'حساب بنكي (IBAN)'),
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentOption(
                    title: isArabic ? 'إنستاباي InstaPay' : 'InstaPay Handle',
                    subtitle: isArabic
                        ? 'سحب فوري إلى معرّف إنستاباي'
                        : 'Instant payout to IPA username',
                    icon: Icons.flash_on_rounded,
                    color: Colors.purpleAccent,
                    isSelected: selectedDest.contains('InstaPay'),
                    onTap: () =>
                        setModalState(() => selectedDest = 'إنستاباي (InstaPay)'),
                  ),
                  const SizedBox(height: 8),
                  _buildPaymentOption(
                    title: isArabic
                        ? 'محفظة فودافون كاش'
                        : 'Vodafone Cash Wallet',
                    subtitle: isArabic
                        ? 'سحب فوري على رقم الهاتف'
                        : 'Instant cashout to mobile wallet',
                    icon: Icons.phone_android_rounded,
                    color: Colors.redAccent,
                    isSelected: selectedDest.contains('فودافون'),
                    onTap: () =>
                        setModalState(() => selectedDest = 'فودافون كاش'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: accountCtl,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: selectedDest.contains('بنكي')
                          ? (isArabic
                              ? 'رقم الآيبان (EG...)'
                              : 'IBAN Number (EG...)')
                          : (selectedDest.contains('InstaPay')
                              ? (isArabic
                                  ? 'معرّف إنستاباي (name@instapay)'
                                  : 'InstaPay Handle')
                              : (isArabic
                                  ? 'رقم هاتف المحفظة (010...)'
                                  : 'Wallet Mobile Number')),
                      prefixIcon: Icon(Icons.pin_outlined,
                          color: context.accentColor),
                      filled: true,
                      fillColor: context.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.borderColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  BouncingTap(
                    scaleFactor: 0.96,
                    onTap: () async {
                      if (selectedAmount <= 0) return;
                      if (selectedAmount > balance) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isArabic
                                  ? 'عذراً، الرصيد المتاح غير كافٍ لإتمام السحب'
                                  : 'Insufficient available balance',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      final success = await _walletService.withdraw(
                        amount: selectedAmount,
                        destination: selectedDest,
                        accountDetails: accountCtl.text.trim().isNotEmpty
                            ? accountCtl.text.trim()
                            : (isArabic ? 'حساب معتمد' : 'Verified Account'),
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (success) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              isArabic
                                  ? 'تم تسجيل طلب السحب بنجاح بقيمة ${selectedAmount.toInt()} ج.م 💸'
                                  : 'Withdrawal of ${selectedAmount.toInt()} EGP submitted successfully!',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppGradients.gold,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          isArabic
                              ? 'سحب فوري الآن (${selectedAmount.toInt()} ج.م)'
                              : 'Withdraw Now (${selectedAmount.toInt()} EGP)',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Digital Verification Receipt Dialog ──
  void _showReceiptDialog(WalletTransaction tx, bool isArabic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(22),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: const Icon(Icons.verified_rounded,
                  color: AppColors.success, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              isArabic ? 'إيصال مالي معتمد' : 'Verified Digital Receipt',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              tx.referenceCode,
              style: GoogleFonts.outfit(
                color: context.accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            _buildReceiptRow(
              isArabic ? 'المبلغ الصافي' : 'Net Amount',
              '${tx.isCredit ? '+' : '-'}${tx.amount.toInt()} ج.م',
              isBold: true,
              valueColor: tx.isCredit ? AppColors.success : context.accentColor,
            ),
            const SizedBox(height: 8),
            _buildReceiptRow(
              isArabic ? 'نوع العملية' : 'Transaction Type',
              tx.title,
            ),
            const SizedBox(height: 8),
            _buildReceiptRow(
              isArabic ? 'وسيلة الدفع / السحب' : 'Method',
              tx.method,
            ),
            const SizedBox(height: 8),
            _buildReceiptRow(
              isArabic ? 'التاريخ والوقت' : 'Date & Time',
              '${tx.date.day}/${tx.date.month}/${tx.date.year} ${tx.date.hour}:${tx.date.minute.toString().padLeft(2, '0')}',
            ),
            const SizedBox(height: 8),
            _buildReceiptRow(
              isArabic ? 'حالة المعاملة' : 'Status',
              isArabic ? 'مكتملة ومؤكدة ✅' : 'Confirmed & Completed ✅',
              valueColor: AppColors.success,
            ),
            const SizedBox(height: 18),
            Text(
              tx.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            BouncingTap(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: Center(
                  child: Text(
                    isArabic ? 'إغلاق الإيصال' : 'Close Receipt',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 12.5,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? context.textPrimary,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? context.accentColor.withValues(alpha: 0.12)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? context.accentColor : context.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: context.accentColor, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().lang;
    final isArabic = lang == 'ar';
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.name ?? (isArabic ? 'عميل سكني المميز' : 'Sakani VIP Resident');
    final balance = _walletService.balance;
    final pendingBalance = _walletService.pendingBalance;
    final allTransactions = _walletService.transactions;

    final filteredTransactions = allTransactions.where((t) {
      if (_selectedCategory == 'topup') return t.category == 'topup';
      if (_selectedCategory == 'withdrawal') return t.category == 'withdrawal';
      if (_selectedCategory == 'earnings') return t.category == 'earnings';
      if (_selectedCategory == 'rent') return t.category == 'rent_payment';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'محفظة سكني الرقمية' : 'Sakani Digital Wallet',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. VIP Black & Gold Virtual Card ──
            Container(
              height: 220,
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF131B2F),
                    Color(0xFF0A0E1A),
                    Color(0xFF060910),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: context.accentColor.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: context.accentColor.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Card Header: Logo, Chip, Contactless
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.token_rounded,
                              color: context.accentColor, size: 26),
                          const SizedBox(width: 8),
                          Text(
                            'SAKANI PAY',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.wifi_rounded,
                              color: Colors.white38, size: 20),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: AppGradients.gold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'VIP PASS',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // EMV Golden Chip Graphic
                  Container(
                    width: 38,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          context.accentColor,
                          AppColors.goldLight,
                          AppColors.goldDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                  ),

                  // Balances
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isArabic ? 'الرصيد المتاح للسحب' : 'Available Balance',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                balance.toStringAsFixed(0).replaceAllMapped(
                                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                      (Match m) => '${m[1]},',
                                    ),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isArabic ? 'ج.م' : 'EGP',
                                style: TextStyle(
                                  color: context.accentColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (pendingBalance > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isArabic ? 'تأمين معلق' : 'Escrow Deposit',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${pendingBalance.toInt()} ج.م',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Cardholder & Masked Number
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '••••  ••••  ••••  9214',
                        style: GoogleFonts.outfit(
                          color: Colors.white38,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 2. Action Buttons (Top Up & Withdraw) ──
            Row(
              children: [
                Expanded(
                  child: BouncingTap(
                    scaleFactor: 0.96,
                    onTap: () => _showTopUpSheet(isArabic),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppGradients.gold,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline_rounded,
                              color: Colors.black, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isArabic ? 'شحن رصيد' : 'Top Up',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BouncingTap(
                    scaleFactor: 0.96,
                    onTap: () => _showWithdrawSheet(isArabic),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.accentColor.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.outbox_rounded,
                              color: context.accentColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isArabic ? 'سحب أرباح' : 'Withdraw',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── 3. Filterable Transaction Ledger ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'سجل المعاملات والعمليات' : 'Transaction History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  '${filteredTransactions.length} ${isArabic ? "معاملة" : "txs"}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Category Filter Pills
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFilterChip('all', isArabic ? 'الكل' : 'All'),
                  _buildFilterChip('earnings', isArabic ? 'أرباح إيجار' : 'Earnings'),
                  _buildFilterChip('topup', isArabic ? 'إيداع وشحن' : 'Top-Up'),
                  _buildFilterChip('withdrawal', isArabic ? 'سحب أرباح' : 'Withdrawals'),
                  _buildFilterChip('rent', isArabic ? 'دفع إيجار' : 'Rent Payments'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Transactions List
            if (filteredTransactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 40, color: context.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      isArabic ? 'لا توجد معاملات بعد' : 'No transactions yet',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTransactions.length,
                itemBuilder: (context, index) {
                  final tx = filteredTransactions[index];
                  final isPositive = tx.isCredit;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      onTap: () => _showReceiptDialog(tx, isArabic),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isPositive
                              ? AppColors.success.withValues(alpha: 0.12)
                              : Colors.amber.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPositive
                              ? (tx.category == 'earnings'
                                  ? Icons.savings_rounded
                                  : Icons.arrow_downward_rounded)
                              : Icons.arrow_upward_rounded,
                          color: isPositive ? AppColors.success : Colors.amber,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        tx.title,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${tx.method} • ${tx.date.day}/${tx.date.month}/${tx.date.year}',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isPositive ? "+" : "-"}${tx.amount.toInt()} ج.م',
                            style: GoogleFonts.outfit(
                              color: isPositive
                                  ? AppColors.success
                                  : context.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                          Text(
                            isArabic ? 'عرض الإيصال ↗' : 'Receipt ↗',
                            style: TextStyle(
                              color: context.accentColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSel = _selectedCategory == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSel
              ? context.accentColor
              : context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSel ? context.accentColor : context.borderColor,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            color: isSel ? Colors.black : context.textSecondary,
          ),
        ),
      ),
    );
  }
}
