import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakani/features/wallet/data/services/wallet_service.dart';
import 'package:sakani/core/widgets/gradient_button.dart';
import 'package:provider/provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();

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

  void _showTopUpSheet() {
    final customCtl = TextEditingController(text: '1000');
    double selectedAmount = 1000;
    String selectedMethod = 'InstaPay (إنستاباي)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceColor,
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
                        child: Icon(Icons.add_card_rounded, color: context.accentColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'شحن رصيد المحفظة',
                        style: GoogleFonts.tajawal(
                          color: context.textPrimary,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Amounts
                  Text(
                    'اختر المبلغ أو حدد قيمة مخصصة',
                    style: GoogleFonts.tajawal(
                      color: context.textSecondary,
                      fontSize: 13,
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
                                  : (context.isDark ? AppColors.darkCard : AppColors.lightCard),
                              borderRadius: AppRadius.smBr,
                              border: Border.all(
                                color: isSel ? context.accentColor : context.borderColor,
                                width: isSel ? 1.8 : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${amt.toInt()} ج.م',
                                style: GoogleFonts.tajawal(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                                  color: isSel ? context.accentColor : context.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: customCtl,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.tajawal(
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    decoration: InputDecoration(
                      labelText: 'المبلغ المطلوب شحنه (بالجنيه)',
                      prefixIcon: Icon(Icons.payments_outlined, color: context.accentColor),
                      suffixText: 'ج.م',
                      suffixStyle: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null) {
                        setModalState(() => selectedAmount = parsed);
                      }
                    },
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'اختر وسيلة الدفع',
                    style: GoogleFonts.tajawal(
                      color: context.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _PaymentOption(
                    title: 'إنستاباي InstaPay',
                    subtitle: 'تحويل فوري بدون أي رسوم إضافية',
                    icon: Icons.flash_on_rounded,
                    color: Colors.purpleAccent,
                    isSelected: selectedMethod.contains('InstaPay'),
                    onTap: () => setModalState(() => selectedMethod = 'InstaPay (إنستاباي)'),
                  ),
                  const SizedBox(height: 8),
                  _PaymentOption(
                    title: 'فودافون كاش / المحافظ الإلكترونية',
                    subtitle: 'الدفع برقم الهاتف عبر محفظتك',
                    icon: Icons.phone_android_rounded,
                    color: Colors.redAccent,
                    isSelected: selectedMethod.contains('فودافون'),
                    onTap: () => setModalState(() => selectedMethod = 'فودافون كاش'),
                  ),
                  const SizedBox(height: 8),
                  _PaymentOption(
                    title: 'بطاقة بنكية (Visa / MasterCard)',
                    subtitle: 'دفع مشفر وآمن عبر البطاقات الائتمانية',
                    icon: Icons.credit_card_rounded,
                    color: Colors.blueAccent,
                    isSelected: selectedMethod.contains('Visa'),
                    onTap: () => setModalState(() => selectedMethod = 'بطاقة بنكية'),
                  ),

                  const SizedBox(height: 24),
                  GradientButton(
                    text: 'تأكيد وشحن ${selectedAmount.toInt()} ج.م',
                    icon: Icons.check_circle_rounded,
                    onPressed: () async {
                      if (selectedAmount <= 0) return;
                      final messenger = ScaffoldMessenger.of(context);
                      await _walletService.topUp(
                        amount: selectedAmount,
                        method: selectedMethod,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'تم شحن ${selectedAmount.toInt()} ج.م بنجاح إلى محفظتك! 🎉',
                              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.name ?? 'عميل سكني المميز';
    final balance = _walletService.balance;
    final transactions = _walletService.transactions;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'محفظة سكني الرقمية',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: context.accentColor),
            onPressed: _showTopUpSheet,
            tooltip: 'شحن رصيد',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Luxury Gold Virtual Card ──
            Container(
              height: 210,
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A), Color(0xFF080C14)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: context.accentColor.withValues(alpha: 0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: context.accentColor.withValues(alpha: 0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.token_rounded, color: context.accentColor, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'SAKANI PAY',
                            style: GoogleFonts.tajawal(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.accentColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'VIP PASS',
                          style: GoogleFonts.tajawal(
                            color: context.accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Balance Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الرصيد المتاح الحالي',
                        style: GoogleFonts.tajawal(
                          color: const Color(0xFF94A3B8),
                          fontSize: 12,
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
                            style: GoogleFonts.tajawal(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ج.م',
                            style: GoogleFonts.tajawal(
                              color: context.accentColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Card Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        userName,
                        style: GoogleFonts.tajawal(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '•••• 8824',
                        style: GoogleFonts.tajawal(
                          color: const Color(0xFF94A3B8),
                          fontSize: 13,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 2. Quick Action Buttons ──
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.accentColor,
                      foregroundColor: const Color(0xFF080C14),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
                    ),
                    onPressed: _showTopUpSheet,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'شحن رصيد',
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textPrimary,
                      side: BorderSide(color: context.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'خدمة سحب الأرباح متاحة لحسابات الملاك عبر إنستاباي والحسابات البنكية',
                            style: GoogleFonts.tajawal(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_outward_rounded, size: 20),
                    label: Text(
                      'سحب أرباح',
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── 3. Transaction History Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سجل المعاملات والمدفوعات',
                  style: GoogleFonts.tajawal(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${transactions.length} معاملة',
                  style: GoogleFonts.tajawal(
                    color: context.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Transaction Cards List
            if (transactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'لا توجد معاملات مسجلة حتى الآن',
                    style: GoogleFonts.tajawal(color: context.textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final isCredit = tx.isCredit;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: AppRadius.mdBr,
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isCredit ? AppColors.success : AppColors.error)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isCredit ? AppColors.success : AppColors.error,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title,
                                style: GoogleFonts.tajawal(
                                  color: context.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${tx.method} • ${tx.date.day}/${tx.date.month}/${tx.date.year}',
                                style: GoogleFonts.tajawal(
                                  color: context.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${isCredit ? '+' : '-'}${tx.amount.toInt()} ج.م',
                          style: GoogleFonts.tajawal(
                            color: isCredit ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? context.accentColor.withValues(alpha: 0.1)
              : (context.isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: AppRadius.smBr,
          border: Border.all(
            color: isSelected ? context.accentColor : context.borderColor,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
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
                    style: GoogleFonts.tajawal(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.tajawal(
                      color: context.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: context.accentColor, size: 20),
          ],
        ),
      ),
    );
  }
}
