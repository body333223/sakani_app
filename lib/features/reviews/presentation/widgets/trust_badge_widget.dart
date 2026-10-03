import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/reviews/domain/models/review_model.dart';
import 'package:sakani/features/reviews/data/services/review_service.dart';

/// شارة الثقة المعتمدة للمستأجرين والملاك
class TrustBadgeWidget extends StatelessWidget {
  final String userId;
  final bool isOwner;
  final bool isCompact;

  const TrustBadgeWidget({
    super.key,
    required this.userId,
    required this.isOwner,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final TrustBadgeData badge = isOwner
        ? ReviewService().getOwnerTrustBadge(userId)
        : ReviewService().getTenantTrustBadge(userId);

    final isDark = context.isDark;

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isOwner
              ? AppColors.gold.withValues(alpha: 0.15)
              : AppColors.success.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isOwner
                ? AppColors.gold.withValues(alpha: 0.4)
                : AppColors.success.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOwner ? Icons.star_rounded : Icons.verified_rounded,
              color: isOwner ? AppColors.gold : AppColors.success,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              badge.title,
              style: GoogleFonts.tajawal(
                color: isOwner ? AppColors.goldLight : AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  isOwner ? const Color(0xFF281E0C) : const Color(0xFF0D251C),
                  isOwner ? const Color(0xFF140F06) : const Color(0xFF06140E),
                ]
              : [
                  isOwner ? const Color(0xFFFEF9C3) : const Color(0xFFDCFCE7),
                  isOwner ? const Color(0xFFFEF08A) : const Color(0xFFBBF7D0),
                ],
        ),
        borderRadius: AppRadius.mdBr,
        border: Border.all(
          color: isOwner ? AppColors.gold.withValues(alpha: 0.5) : AppColors.success.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isOwner ? AppColors.gold : AppColors.success).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (isOwner ? AppColors.gold : AppColors.success).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOwner ? Icons.star_rounded : Icons.shield_rounded,
              color: isOwner ? AppColors.gold : AppColors.success,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                badge.title,
                style: GoogleFonts.tajawal(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isOwner
                      ? (isDark ? AppColors.goldLight : const Color(0xFF854D0E))
                      : (isDark ? AppColors.success : const Color(0xFF14532D)),
                ),
              ),
              Text(
                badge.subtitle,
                style: GoogleFonts.tajawal(
                  fontSize: 10,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
