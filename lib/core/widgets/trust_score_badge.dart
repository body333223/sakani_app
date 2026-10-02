import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';

/// شارة مؤشر الثقة (Sakani Trust Score) والتقييم المزدوج
class TrustScoreBadge extends StatelessWidget {
  final double score; // e.g. 98.0
  final int completedDeals;
  final bool isVerified;
  final double rating;
  final VoidCallback? onOpenReviews;

  const TrustScoreBadge({
    super.key,
    this.score = 98.5,
    this.completedDeals = 24,
    this.isVerified = true,
    this.rating = 4.9,
    this.onOpenReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenReviews ?? () => _showTrustModal(context),
        borderRadius: AppRadius.mdBr,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.gold.withValues(alpha: 0.15),
                context.surfaceColor,
              ],
            ),
            borderRadius: AppRadius.mdBr,
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded, color: AppColors.gold, size: 16),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'مؤشر الثقة ${score.toStringAsFixed(0)}%',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: AppColors.success, size: 13),
                    ],
                  ),
                  Text(
                    '$completedDeals عملية ناجحة • ⭐ $rating',
                    style: GoogleFonts.tajawal(
                      fontSize: 10,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrustModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppColors.gold, size: 28),
                const SizedBox(width: 10),
                Text(
                  'تفاصيل مؤشر الثقة (Trust Score)',
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _CriterionRow(title: 'توثيق الهوية الرسمية (KYC)', status: 'معتمد ومؤكد بالرقم القومي', isPassed: true),
            _CriterionRow(title: 'الالتزام بمواعيد السداد والتسليم', status: '100% نسبة الالتزام', isPassed: true),
            _CriterionRow(title: 'تقييمات النظافة والأمانة', status: '4.9 من 5.0 (24 تقييم)', isPassed: true),
            _CriterionRow(title: 'عقود موثقة إلكترونياً', status: '18 عقد مسجل', isPassed: true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAddReviewDialog(context);
                },
                icon: const Icon(Icons.rate_review_rounded, size: 18),
                label: Text('إضافة تقييم جديد للمستخدم', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.accentColor,
                  foregroundColor: const Color(0xFF080C14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context) {
    int ratingStars = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: context.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
          title: Text(
            'تقييم الطرف الآخر (مؤجر / مستأجر)',
            style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'التقييم المتبادل يحمي مجتمع سكني ويرفع موثوقية الحسابات:',
                style: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= ratingStars ? Icons.star_rounded : Icons.star_border_rounded,
                      color: AppColors.gold,
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() => ratingStars = starIndex);
                    },
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: commentCtrl,
                maxLines: 3,
                style: GoogleFonts.tajawal(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'اكتب ملاحظاتك عن التجربة والنظافة والتواصل...',
                  hintStyle: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary),
                  border: OutlineInputBorder(borderRadius: AppRadius.smBr),
                  filled: true,
                  fillColor: context.cardColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: TextStyle(color: context.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                AppSnackbar.show(
                  context,
                  message: 'تم تسجيل التقييم بنجاح وتحديث مؤشر الثقة 🌟',
                  type: ToastType.success,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF080C14),
              ),
              child: const Text('إرسال التقييم'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CriterionRow extends StatelessWidget {
  final String title;
  final String status;
  final bool isPassed;

  const _CriterionRow({
    required this.title,
    required this.status,
    required this.isPassed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isPassed ? AppColors.success : Colors.redAccent,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary)),
                Text(status, style: GoogleFonts.tajawal(fontSize: 10, color: context.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
