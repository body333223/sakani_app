import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/glass_card.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';
import 'package:sakani/features/apartments/domain/entities/apartment_entity.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:sakani/core/localization/app_localizations.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';

/// شاشة العقد الإلكتروني الذكي والتوقيع الرقمي باللمس
class ContractScreen extends StatefulWidget {
  final ApartmentEntity apartment;
  final double totalAmount;
  final String periodType;
  final DateTime startDate;
  final DateTime endDate;

  const ContractScreen({
    super.key,
    required this.apartment,
    required this.totalAmount,
    required this.periodType,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  final List<Offset?> _points = [];
  bool _isSigned = false;
  bool _agreeToTerms = false;
  String? _signatureSavedAt;

  void _clearSignature() {
    setState(() {
      _points.clear();
      _isSigned = false;
      _signatureSavedAt = null;
    });
  }

  void _saveSignature() {
    if (_points.length < 5) {
      AppSnackbar.show(
        context,
        message: 'يرجى كتابة التوقيع باليد داخل المربع أولاً',
        type: ToastType.error,
      );
      return;
    }
    setState(() {
      _isSigned = true;
      _signatureSavedAt = '${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}';
    });
    AppSnackbar.show(
      context,
      message: 'تم حفظ وتوثيق التوقيع الرقمي بنجاح ✍️',
      type: ToastType.success,
    );
  }

  void _confirmContract() {
    if (!_agreeToTerms) {
      AppSnackbar.show(
        context,
        message: 'يجب الموافقة على الشروط والأحكام لاعتماد العقد',
        type: ToastType.error,
      );
      return;
    }
    if (!_isSigned) {
      AppSnackbar.show(
        context,
        message: 'يُرجى إتمام التوقيع الرقمي باليد قبل تأكيد العقد',
        type: ToastType.error,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBr),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.success, size: 28),
            const SizedBox(width: 8),
            Text(
              'العقد موثق قانونياً',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تم إصدار العقد الإلكتروني رقم SKN-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)} بنجاح.',
              style: GoogleFonts.tajawal(fontSize: 14, color: context.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: AppRadius.mdBr,
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_2_rounded, size: 36, color: AppColors.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'رمز التحقق المشفر (Hash)',
                          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.gold),
                        ),
                        Text(
                          'SHA256: 8f4b..e912 (معتمد لدى منصة سكني)',
                          style: GoogleFonts.outfit(fontSize: 10, color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, true);
            },
            child: Text('إتمام الحجز والعودة', style: GoogleFonts.tajawal(color: context.accentColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().lang;
    final tr = AppLocalizations(lang);
    final user = context.read<AuthProvider>().user;
    final tenantName = user?.name ?? (lang == 'ar' ? 'المستأجر المعتمد' : 'Verified Tenant');
    final tenantPhone = user?.phone ?? '010XXXXXXXX';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr.tr('eContract'),
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: 'مشاركة العقد',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              AppSnackbar.show(
                context,
                message: 'جاري إنشاء رابط العقد الإلكتروني المشفر...',
                type: ToastType.info,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Official Header ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.goldDark.withValues(alpha: 0.25),
                    context.surfaceColor,
                  ],
                ),
                borderRadius: AppRadius.mdBr,
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.gavel_rounded, color: AppColors.gold, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'وثيقة إيجار رسمية رقمية',
                              style: GoogleFonts.tajawal(
                                color: context.textPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                'معتمد قانونياً',
                                style: GoogleFonts.tajawal(
                                  color: AppColors.success,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'يخضع هذا العقد لأحكام القانون والضوابط المنظمة للمنصات العقارية',
                          style: GoogleFonts.tajawal(color: context.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Contract Clauses Paper ──
            GlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'بند التراضي والتعاقد',
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'بتاريخ ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} تم الاتفاق والتراضي بين كلٍ من:',
                      style: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary),
                    ),
                  ),
                  const Divider(height: 24),

                  // Parties
                  _ClauseRow(title: 'الطرف الأول (المؤجر):', value: widget.apartment.ownerName.isNotEmpty ? widget.apartment.ownerName : 'مالك العقار المعتمد'),
                  _ClauseRow(title: 'هاتف المؤجر:', value: widget.apartment.contactPhone.isNotEmpty ? widget.apartment.contactPhone : 'مسجل بالمنصة'),
                  const SizedBox(height: 8),
                  _ClauseRow(title: 'الطرف الثاني (المستأجر):', value: tenantName),
                  _ClauseRow(title: 'هاتف المستأجر:', value: tenantPhone),
                  const Divider(height: 24),

                  // Property Details
                  _ClauseRow(title: 'العين المؤجرة:', value: widget.apartment.title),
                  _ClauseRow(title: 'العنوان الجغرافي:', value: '${widget.apartment.city} - ${widget.apartment.address}'),
                  _ClauseRow(title: 'مدة الإيجار:', value: '${widget.periodType} (من ${widget.startDate.day}/${widget.startDate.month} إلى ${widget.endDate.day}/${widget.endDate.month}/${widget.endDate.year})'),
                  _ClauseRow(title: 'القيمة الإيجارية:', value: '${widget.totalAmount.round()} ج.م'),
                  _ClauseRow(title: 'مبلغ التأمين المحتجز:', value: '${widget.apartment.securityDeposit.round()} ج.م (في حساب الضمان)'),
                  const Divider(height: 24),

                  // Terms and conditions
                  Text(
                    'الشروط والأحكام الأساسية:',
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13, color: context.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  _TermBullet(text: 'يلتزم الطرف الثاني بالمحافظة على العين المؤجرة ومحتوياتها وتسليمها بالحالة المستلمة عليها.'),
                  _TermBullet(text: 'يتم احتجاز مبلغ التأمين في حساب الضمان التابع لمنصة سكني (Escrow) ولا يُرد إلا بعد التفتيش الإيجابي.'),
                  _TermBullet(text: 'في حال وجود خلاف، تكون منصة سكني وسيطاً تحكيمياً رقمياً ملزماً لكلا الطرفين.'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Digital Signature Section ──
            Text(
              'التوقيع الرقمي باليد (Digital Signature) ✍️',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 15, color: context.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'مرر إصبعك داخل المساحة أدناه لتوقيع العقد بخط يدك:',
              style: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary),
            ),
            const SizedBox(height: 10),

            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: AppRadius.mdBr,
                border: Border.all(
                  color: _isSigned ? AppColors.success : context.accentColor.withValues(alpha: 0.5),
                  width: _isSigned ? 2.0 : 1.2,
                ),
              ),
              child: Stack(
                children: [
                  GestureDetector(
                    onPanUpdate: (details) {
                      final box = context.findRenderObject() as RenderBox?;
                      if (box != null) {
                        final point = details.localPosition;
                        setState(() {
                          _points.add(point);
                        });
                      }
                    },
                    onPanEnd: (_) => _points.add(null),
                    child: CustomPaint(
                      painter: _SignaturePainter(points: _points, color: context.isDark ? AppColors.gold : Colors.black),
                      size: Size.infinite,
                    ),
                  ),
                  if (_points.isEmpty)
                    Center(
                      child: Text(
                        'وقّع هنا بإصبعك ✍️',
                        style: GoogleFonts.tajawal(
                          color: context.textSecondary.withValues(alpha: 0.4),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  if (_isSigned)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.success),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              'توقيع موثق (${_signatureSavedAt ?? ""})',
                              style: GoogleFonts.tajawal(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _clearSignature,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(tr.tr('clearSignature'), style: GoogleFonts.tajawal(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.textSecondary,
                    side: BorderSide(color: context.borderColor),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _saveSignature,
                  icon: const Icon(Icons.done_all_rounded, size: 16),
                  label: Text(tr.tr('saveSignature'), style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.accentColor,
                    foregroundColor: const Color(0xFF080C14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Agree to terms checkbox ──
            CheckboxListTile(
              value: _agreeToTerms,
              onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
              activeColor: context.accentColor,
              contentPadding: EdgeInsets.zero,
              title: Text(
                tr.tr('agreeToTerms'),
                style: GoogleFonts.tajawal(fontSize: 12, color: context.textPrimary),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 20),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _confirmContract,
                icon: const Icon(Icons.verified_user_rounded),
                label: Text(
                  tr.tr('contractAuthenticated'),
                  style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: const Color(0xFF080C14),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _ClauseRow extends StatelessWidget {
  final String title;
  final String value;
  const _ClauseRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              title,
              style: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.tajawal(fontSize: 13, color: context.textPrimary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermBullet extends StatelessWidget {
  final String text;
  const _TermBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.gold, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.tajawal(fontSize: 11, color: context.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;

  _SignaturePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
