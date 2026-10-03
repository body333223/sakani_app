import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/glass_card.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';
import 'package:sakani/features/contracts/domain/models/contract_model.dart';
import 'package:sakani/features/contracts/data/services/contract_pdf_service.dart';

/// شاشة عرض وثيقة عقد الإيجار الرسمي الموثق رقمياً
class DigitalContractScreen extends StatefulWidget {
  final ContractModel contract;

  const DigitalContractScreen({super.key, required this.contract});

  @override
  State<DigitalContractScreen> createState() => _DigitalContractScreenState();
}

class _DigitalContractScreenState extends State<DigitalContractScreen> {
  bool _isGeneratingPdf = false;

  Future<void> _downloadOrExportPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdfBytes = await ContractPdfService.generateContractPdf(widget.contract);
      if (!mounted) return;

      AppSnackbar.show(
        context,
        message: 'تم توليد وحفظ ملف العقد PDF بنجاح (${(pdfBytes.lengthInBytes / 1024).round()} KB) 📄',
        type: ToastType.success,
      );

      // Dialog with summary and actions
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBr),
          title: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, color: AppColors.gold, size: 28),
              const SizedBox(width: 8),
              Text(
                'عقد الإيجار الموثق PDF',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تم إنشاء وثيقة العقد الرسمية المعتمدة رقم ${widget.contract.id}',
                style: GoogleFonts.tajawal(fontSize: 13, color: context.textPrimary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mdBr,
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الحالة: معتمد وموثق رقمياً', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.success)),
                          Text('البصمة الرقمية: ${widget.contract.digitalHash.substring(0, 16)}...', style: GoogleFonts.outfit(fontSize: 10, color: context.textSecondary)),
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
              onPressed: () => Navigator.pop(ctx),
              child: Text('إغلاق', style: GoogleFonts.tajawal(color: context.textSecondary)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: widget.contract.qrData));
                AppSnackbar.show(
                  context,
                  message: 'تم نسخ رابط التحقق الرسمي إلى الحافظة 📋',
                  type: ToastType.info,
                );
              },
              icon: const Icon(Icons.share_rounded, size: 16),
              label: Text('مشاركة رابط التحقق', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF080C14),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: 'حدث خطأ أثناء تصدير العقد: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _copyHash() {
    Clipboard.setData(ClipboardData(text: widget.contract.digitalHash));
    AppSnackbar.show(
      context,
      message: 'تم نسخ البصمة الرقمية المشفرة (SHA-256) إلى الحافظة 🔒',
      type: ToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contract;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070A11) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(
          'عقد إيجار إلكتروني موثق',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: 'تصدير PDF',
            icon: _isGeneratingPdf
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold))
                : const Icon(Icons.download_rounded, color: AppColors.gold),
            onPressed: _isGeneratingPdf ? null : _downloadOrExportPdf,
          ),
          IconButton(
            tooltip: 'نسخ البصمة المشفرة',
            icon: const Icon(Icons.fingerprint_rounded),
            onPressed: _copyHash,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // ── Official Egyptian Escrow Legal Document Header ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.goldDark.withValues(alpha: 0.3),
                    isDark ? const Color(0xFF0F172A) : Colors.white,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: AppRadius.lgBr,
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, color: AppColors.success, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'موثق ومعتمد رسمياً',
                              style: GoogleFonts.tajawal(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'منصة سكني - حساب الضمان',
                        style: GoogleFonts.tajawal(fontSize: 11, color: context.textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Icon(Icons.gavel_rounded, color: AppColors.gold, size: 38),
                  const SizedBox(height: 6),
                  Text(
                    'وثيقة عقد إيجار إلكتروني موثق',
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.goldLight : const Color(0xFF854D0E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'رقم العقد: ${c.id}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'تاريخ التوثيق: ${c.createdAt.day}/${c.createdAt.month}/${c.createdAt.year} - ${c.createdAt.hour}:${c.createdAt.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.tajawal(fontSize: 11, color: context.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Parties Credentials Box ──
            GlassCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_alt_rounded, color: AppColors.gold, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'بيانات طرفي العقد (معتمدة بالرقم القومي)',
                        style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Owner
                  _PartyCard(
                    title: 'الطرف الأول (المؤجر / المالك):',
                    name: c.ownerName,
                    nationalId: c.ownerNationalId,
                    phone: c.ownerPhone,
                    roleIcon: Icons.home_work_rounded,
                    isVerified: true,
                  ),
                  const SizedBox(height: 12),

                  // Tenant
                  _PartyCard(
                    title: 'الطرف الثاني (المستأجر):',
                    name: c.tenantName,
                    nationalId: c.tenantNationalId,
                    phone: c.tenantPhone,
                    roleIcon: Icons.person_pin_rounded,
                    isVerified: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Unit and Financial Escrow Box ──
            GlassCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.apartment_rounded, color: AppColors.gold, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'بيانات العين المؤجرة والضمان المالي',
                        style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  _DataRow(label: 'العين المؤجرة:', value: c.apartmentTitle),
                  _DataRow(label: 'الموقع الجغرافي:', value: '${c.apartmentCity} - ${c.apartmentAddress}'),
                  _DataRow(
                    label: 'فترة الإيجار:',
                    value: 'من ${c.startDate.day}/${c.startDate.month}/${c.startDate.year} إلى ${c.endDate.day}/${c.endDate.month}/${c.endDate.year} (${c.periodType})',
                  ),
                  _DataRow(
                    label: 'القيمة الإيجارية:',
                    value: '${c.totalRent.round()} ج.م',
                    valueColor: AppColors.success,
                    isBold: true,
                  ),
                  _DataRow(
                    label: 'التأمين بحساب الضمان (Escrow):',
                    value: '${c.securityDeposit.round()} ج.م (محمي رقمياً)',
                    valueColor: AppColors.warning,
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Legal Clauses Box ──
            GlassCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.balance_rounded, color: AppColors.gold, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'البنود القانونية الملزمة (طبقا للقانون المصري)',
                        style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _LegalClause(
                    number: '١',
                    text: 'أقر الطرفان بأهليتهما القانونية والشرعية للتعاقد دون إكراه أو تدليس، وتعتبر التوقيعات الرقمية ملزمة ونهائية قانونياً.',
                  ),
                  _LegalClause(
                    number: '٢',
                    text: 'يلتزم المستأجر بالمحافظة على العين المؤجرة وملحقاتها ومراعاة حسن الجوار، وعدم إحداث أي تغييرات جوهرية بدون إذن كتابي من المؤجر.',
                  ),
                  _LegalClause(
                    number: '٣',
                    text: 'يتم إيداع مبلغ التأمين في حساب الضمان البنكي التابع لمنصة سكني (Escrow Protection) ولا يُصرف لأي طرف إلا بعد التحقق من انتهاء التعاقد وسلامة العين.',
                  ),
                  _LegalClause(
                    number: '٤',
                    text: 'تعد منصة سكني وسيطاً تحكيمياً رقمياً معتمداً لفض أي نزاع إيجاري بين الطرفين بناءً على السجلات والبيانات الرقمية المشفرة.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Cryptographic Seal & Live QR Verification ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: AppRadius.lgBr,
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.qr_code_2_rounded, size: 40, color: AppColors.gold),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'البصمة الرقمية المشفرة للعقد',
                              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.gold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'SHA-256 Digital Fingerprint Seal',
                              style: GoogleFonts.outfit(fontSize: 10, color: context.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              c.digitalHash,
                              style: GoogleFonts.sourceCodePro(
                                fontSize: 9,
                                color: context.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'توقيع المؤجر: موثق رقمياً ✓',
                        style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'توقيع المستأجر: موثق رقمياً ✓',
                        style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Export & Action Buttons ──
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isGeneratingPdf ? null : _downloadOrExportPdf,
                      icon: _isGeneratingPdf
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF080C14)))
                          : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                      label: Text(
                        'تحميل العقد PDF 📄',
                        style: GoogleFonts.tajawal(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: const Color(0xFF080C14),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
                        elevation: 3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: c.qrData));
                      AppSnackbar.show(
                        context,
                        message: 'تم نسخ رابط التحقق الرسمي للعقد 📋',
                        type: ToastType.success,
                      );
                    },
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: Text(
                      'مشاركة',
                      style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.textPrimary,
                      side: BorderSide(color: context.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _PartyCard extends StatelessWidget {
  final String title;
  final String name;
  final String nationalId;
  final String phone;
  final IconData roleIcon;
  final bool isVerified;

  const _PartyCard({
    required this.title,
    required this.name,
    required this.nationalId,
    required this.phone,
    required this.roleIcon,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.surfaceColor.withValues(alpha: 0.6),
        borderRadius: AppRadius.mdBr,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(roleIcon, size: 16, color: AppColors.gold),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gold),
              ),
              const Spacer(),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'هوية موثقة ✓',
                    style: GoogleFonts.tajawal(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.success),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الاسم: $name', style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold, color: context.textPrimary)),
              Text('الهاتف: $phone', style: GoogleFonts.outfit(fontSize: 12, color: context.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('الرقم القومي: ', style: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary)),
              SelectableText(
                nationalId,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldLight,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _DataRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.tajawal(
                fontSize: 13,
                color: valueColor ?? context.textPrimary,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalClause extends StatelessWidget {
  final String number;
  final String text;

  const _LegalClause({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: GoogleFonts.tajawal(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
