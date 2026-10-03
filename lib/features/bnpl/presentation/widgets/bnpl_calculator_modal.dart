import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';
import 'package:sakani/core/widgets/gradient_button.dart';
import 'package:sakani/core/widgets/notifications_bottom_sheet.dart';

/// ويدجت حاسبة التقسيط "اسكن الآن وادفع لاحقاً" (Rent Now, Pay Later - BNPL)
class BnplCalculatorModal extends StatefulWidget {
  final double totalRent;
  final String apartmentTitle;

  const BnplCalculatorModal({
    super.key,
    required this.totalRent,
    required this.apartmentTitle,
  });

  static void show(BuildContext context, {required double totalRent, required String apartmentTitle}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BnplCalculatorModal(
        totalRent: totalRent,
        apartmentTitle: apartmentTitle,
      ),
    );
  }

  @override
  State<BnplCalculatorModal> createState() => _BnplCalculatorModalState();
}

class _BnplCalculatorModalState extends State<BnplCalculatorModal> {
  int _selectedMonths = 6; // 3, 6, 12
  String _selectedProvider = 'valu'; // valu, fawry, souhoola, aman

  final Map<String, (String, Color)> _providers = {
    'valu': ('ڤاليو ValU', Colors.orange),
    'fawry': ('فوري تقسيط', Colors.amber),
    'souhoola': ('سهولة Souhoola', Colors.teal),
    'aman': ('أمان Aman', Colors.blue),
  };

  double get _monthlyInstallment {
    // Interest factor simulation (e.g. 1.5% monthly admin fee)
    final interestFactor = 1.0 + (_selectedMonths * 0.015);
    return (widget.totalRent * interestFactor) / _selectedMonths;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.credit_score_rounded, color: AppColors.gold, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'اسكن الآن وادفع لاحقاً (تقسيط)',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.apartmentTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Total Rent Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('إجمالي قيمة الإيجار المطلوب:', style: TextStyle(color: context.textSecondary, fontSize: 13)),
                Text(
                  '${widget.totalRent.round()} ج.م',
                  style: TextStyle(color: context.accentColor, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Duration Selector (3, 6, 12 months)
          Text('مدة التقسيط:', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [3, 6, 12].map((m) {
              final isSel = _selectedMonths == m;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => setState(() => _selectedMonths = m),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSel ? context.accentColor : context.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSel ? context.accentColor : context.borderColor),
                      ),
                      child: Center(
                        child: Text(
                          '$m شهور',
                          style: TextStyle(
                            color: isSel ? Colors.black : context.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          // Financing Partner
          Text('شريك التمويل:', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _providers.entries.map((entry) {
              final isSel = _selectedProvider == entry.key;
              return ChoiceChip(
                label: Text(entry.value.$1),
                selected: isSel,
                selectedColor: entry.value.$2.withValues(alpha: 0.2),
                backgroundColor: context.cardColor,
                labelStyle: TextStyle(
                  color: isSel ? entry.value.$2 : context.textSecondary,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: isSel ? entry.value.$2 : context.borderColor),
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedProvider = entry.key);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Monthly Estimated Installment
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.15),
                  AppColors.goldDark.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('القسط الشهري التقديري:', style: TextStyle(color: AppColors.gold, fontSize: 12)),
                    Text(
                      '${_monthlyInstallment.round()} ج.م / شهر',
                      style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 28),
              ],
            ),
          ),
          const SizedBox(height: 22),

          GradientButton(
            text: 'تقديم طلب التقسيط الفوري ⚡',
            onPressed: () {
              Navigator.pop(context);
              NotificationsBottomSheet.addNotification(
                title: 'تم تقديم طلب التقسيط بنجاح 💳',
                body: 'طلب تقسيط إيجار "${widget.apartmentTitle}" على $_selectedMonths شهر قيد المراجعة الفورية مع ${_providers[_selectedProvider]!.$1}.',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
              );
              AppSnackbar.show(
                context,
                message: 'تم إرسال طلب التقسيط لشركة التمويل للموافقة الفورية 💳',
                type: ToastType.success,
              );
            },
          ),
        ],
      ),
    );
  }
}
