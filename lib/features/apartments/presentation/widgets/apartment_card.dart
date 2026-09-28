import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';

class ApartmentCard extends StatelessWidget {
  final Apartment apartment;
  final VoidCallback onTap;

  const ApartmentCard({
    super.key,
    required this.apartment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgBr,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppGradients.card(context),
              borderRadius: AppRadius.lgBr,
              border: Border.all(
                color: context.borderColor.withValues(alpha: 0.6),
              ),
              boxShadow: AppShadows.card(context),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image Section ──
                Stack(
                  children: [
                    Hero(
                      tag: 'apartment_${apartment.id}',
                      child: Container(
                        height: 190,
                        width: double.infinity,
                        color: context.cardColor,
                        child: apartment.images.isNotEmpty
                            ? Image.network(
                                apartment.images[0],
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _ImagePlaceholder(color: context.cardColor),
                              )
                            : _ImagePlaceholder(color: context.cardColor),
                      ),
                    ),
                    // ── Price Badge ──
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF080C14).withValues(alpha: 0.85),
                          borderRadius: AppRadius.pillBr,
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${apartment.monthlyPrice.round()} جنية',
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              ' / شهري',
                              style: TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ── City Badge ──
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF080C14).withValues(alpha: 0.85),
                          borderRadius: AppRadius.pillBr,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.gold,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              apartment.city,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // ── Info Section ──
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        apartment.title,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      // ── Specs Row ──
                      Row(
                        children: [
                          _SpecChip(
                            icon: Icons.bed_rounded,
                            value: '${apartment.bedrooms}',
                          ),
                          const SizedBox(width: 12),
                          _SpecChip(
                            icon: Icons.bathtub_rounded,
                            value: '${apartment.bathrooms}',
                          ),
                          const SizedBox(width: 12),
                          _SpecChip(
                            icon: Icons.square_foot_rounded,
                            value: '${apartment.area} م²',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // ── Address ──
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            color: context.textSecondary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              apartment.address,
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Spec Chip ──
class _SpecChip extends StatelessWidget {
  final IconData icon;
  final String value;

  const _SpecChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.accentColor.withValues(alpha: 0.08),
        borderRadius: AppRadius.smBr,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.accentColor, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Image Placeholder ──
class _ImagePlaceholder extends StatelessWidget {
  final Color color;
  const _ImagePlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 48,
              color: context.accentColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 6),
            Text(
              'لا توجد صورة',
              style: TextStyle(
                color: context.textSecondary.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
