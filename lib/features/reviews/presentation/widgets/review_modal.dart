import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';
import 'package:sakani/features/bookings/data/models/booking_model.dart';
import 'package:sakani/features/reviews/domain/models/review_model.dart';
import 'package:sakani/features/reviews/data/services/review_service.dart';

/// نوافذ التقييم المتبادل (المستأجر يقيم المالك والشقة / والمالك يقيم التزام المستأجر)
class ReviewModals {
  /// نافذة تقييم المستأجر للشقة والمالك
  static Future<void> showTenantReviewModal(
    BuildContext context, {
    required Booking booking,
    required VoidCallback onSubmitted,
  }) async {
    double overall = 5.0;
    double cleanliness = 5.0;
    double communication = 5.0;
    double accuracy = 5.0;
    final tags = <String>{};
    final commentCtrl = TextEditingController();

    const availableTags = [
      'نظيفة جداً',
      'مالك محترم وسريع الرد',
      'مطابقة للصور تماماً',
      'موقع هادئ ومميز',
      'إجراءات دخول سلسة',
      'أثاث راقي ومريح',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              border: Border.all(color: context.borderColor),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star_rounded, color: AppColors.gold, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تقييم الشقة وتجربة الإقامة ⭐',
                              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimary),
                            ),
                            Text(
                              booking.apartmentTitle,
                              style: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Rating Bars
                  _RatingCategoryRow(
                    title: 'التقييم الإجمالي العام',
                    rating: overall,
                    onChanged: (val) => setState(() => overall = val),
                  ),
                  _RatingCategoryRow(
                    title: 'نظافة الشقة والأثاث',
                    rating: cleanliness,
                    onChanged: (val) => setState(() => cleanliness = val),
                  ),
                  _RatingCategoryRow(
                    title: 'تواصل المالك وسرعة الاستجابة',
                    rating: communication,
                    onChanged: (val) => setState(() => communication = val),
                  ),
                  _RatingCategoryRow(
                    title: 'دقة الوصف ومطابقة الصور',
                    rating: accuracy,
                    onChanged: (val) => setState(() => accuracy = val),
                  ),

                  const SizedBox(height: 14),
                  Text(
                    'عبارات مميزة وتأكيدات:',
                    style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableTags.map((tag) {
                      final isSelected = tags.contains(tag);
                      return FilterChip(
                        label: Text(tag, style: GoogleFonts.tajawal(fontSize: 11)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              tags.add(tag);
                            } else {
                              tags.remove(tag);
                            }
                          });
                        },
                        selectedColor: AppColors.gold.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.gold,
                        side: BorderSide(
                          color: isSelected ? AppColors.gold : context.borderColor,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    style: GoogleFonts.tajawal(fontSize: 13, color: context.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'اكتب كلمة موجزة عن تجربتك مع هذه الشقة والمالك...',
                      hintStyle: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary),
                      filled: true,
                      fillColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: AppRadius.mdBr, borderSide: BorderSide(color: context.borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: AppRadius.mdBr, borderSide: BorderSide(color: context.borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: AppRadius.mdBr, borderSide: const BorderSide(color: AppColors.gold)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final rev = ReviewModel(
                          id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
                          bookingId: booking.id,
                          apartmentId: booking.apartmentId,
                          apartmentTitle: booking.apartmentTitle,
                          reviewerId: booking.tenantId,
                          reviewerName: booking.tenantName,
                          reviewerRole: 'tenant',
                          targetId: booking.ownerId,
                          targetRole: 'owner',
                          overallRating: overall,
                          cleanlinessRating: cleanliness,
                          communicationRating: communication,
                          commitmentRating: accuracy,
                          comment: commentCtrl.text.trim().isNotEmpty
                              ? commentCtrl.text.trim()
                              : 'تجربة إقامة ممتازة وشقة راقية جداً.',
                          tags: tags.toList(),
                        );

                        await ReviewService().submitReview(rev);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          AppSnackbar.show(
                            context,
                            message: 'تم تسجيل ونشر تقييمك بنجاح! شكراً لمساهمتك 🌟',
                            type: ToastType.success,
                          );
                          onSubmitted();
                        }
                      },
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: Text(
                        'نشر التقييم واعتماد الشارة 🌟',
                        style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: const Color(0xFF080C14),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// نافذة تقييم المالك لالتزام المستأجر (Mutual Review for Tenant)
  static Future<void> showOwnerReviewModal(
    BuildContext context, {
    required Booking booking,
    required VoidCallback onSubmitted,
  }) async {
    double overall = 5.0;
    double careAndCleanliness = 5.0;
    double paymentAndPunctuality = 5.0;
    double rulesCompliance = 5.0;
    final tags = <String>{};
    final commentCtrl = TextEditingController();

    const availableTags = [
      'مستأجر راقي ومحترم',
      'حافظ على نظافة الشقة',
      'ملتزم بمواعيد الدفع',
      'احترام تام للجيران',
      'تسليم العين بحالة ممتازة',
      'يُنصح بالتعامل معه 🎖️',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              border: Border.all(color: context.borderColor),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تقييم التزام المستأجر 🎖️',
                              style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16, color: context.textPrimary),
                            ),
                            Text(
                              'المستأجر: ${booking.tenantName}',
                              style: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Rating Bars
                  _RatingCategoryRow(
                    title: 'التقييم العام للمستأجر',
                    rating: overall,
                    onChanged: (val) => setState(() => overall = val),
                  ),
                  _RatingCategoryRow(
                    title: 'المحافظة على نظافة الشقة والأثاث',
                    rating: careAndCleanliness,
                    onChanged: (val) => setState(() => careAndCleanliness = val),
                  ),
                  _RatingCategoryRow(
                    title: 'الالتزام المالي ومواعيد الحضور والمغادرة',
                    rating: paymentAndPunctuality,
                    onChanged: (val) => setState(() => paymentAndPunctuality = val),
                  ),
                  _RatingCategoryRow(
                    title: 'احترام قواعد السكن وحسن الجوار',
                    rating: rulesCompliance,
                    onChanged: (val) => setState(() => rulesCompliance = val),
                  ),

                  const SizedBox(height: 14),
                  Text(
                    'شارات الثقة والثناء:',
                    style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableTags.map((tag) {
                      final isSelected = tags.contains(tag);
                      return FilterChip(
                        label: Text(tag, style: GoogleFonts.tajawal(fontSize: 11)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              tags.add(tag);
                            } else {
                              tags.remove(tag);
                            }
                          });
                        },
                        selectedColor: AppColors.success.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.success,
                        side: BorderSide(
                          color: isSelected ? AppColors.success : context.borderColor,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    style: GoogleFonts.tajawal(fontSize: 13, color: context.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'اكتب تقييمك لالتزام وسلوك المستأجر لتوثيق شارة الثقة لديه...',
                      hintStyle: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary),
                      filled: true,
                      fillColor: context.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: AppRadius.mdBr, borderSide: BorderSide(color: context.borderColor)),
                      enabledBorder: OutlineInputBorder(borderRadius: AppRadius.mdBr, borderSide: BorderSide(color: context.borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: AppRadius.mdBr, borderSide: const BorderSide(color: AppColors.success)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final rev = ReviewModel(
                          id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
                          bookingId: booking.id,
                          apartmentId: booking.apartmentId,
                          apartmentTitle: booking.apartmentTitle,
                          reviewerId: booking.ownerId,
                          reviewerName: 'المالك المعتمد',
                          reviewerRole: 'owner',
                          targetId: booking.tenantId,
                          targetRole: 'tenant',
                          overallRating: overall,
                          cleanlinessRating: careAndCleanliness,
                          communicationRating: rulesCompliance,
                          commitmentRating: paymentAndPunctuality,
                          comment: commentCtrl.text.trim().isNotEmpty
                              ? commentCtrl.text.trim()
                              : 'مستأجر ممتاز ومحترم جداً والتزام كامل.',
                          tags: tags.toList(),
                        );

                        await ReviewService().submitReview(rev);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          AppSnackbar.show(
                            context,
                            message: 'تم توثيق تقييم المستأجر وترقية شارة الثقة بنجاح 🎖️',
                            type: ToastType.success,
                          );
                          onSubmitted();
                        }
                      },
                      icon: const Icon(Icons.verified_rounded, size: 18),
                      label: Text(
                        'اعتماد تقييم المستأجر وشارة الثقة 🎖️',
                        style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RatingCategoryRow extends StatelessWidget {
  final String title;
  final double rating;
  final ValueChanged<double> onChanged;

  const _RatingCategoryRow({
    required this.title,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.tajawal(fontSize: 12, color: context.textPrimary, fontWeight: FontWeight.w600),
          ),
          Row(
            children: List.generate(5, (index) {
              final starVal = index + 1.0;
              final isFilled = rating >= starVal;
              return GestureDetector(
                onTap: () => onChanged(starVal),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFilled ? AppColors.gold : context.textSecondary.withValues(alpha: 0.4),
                    size: 24,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
