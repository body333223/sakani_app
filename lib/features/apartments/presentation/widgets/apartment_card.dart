import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';

class ApartmentCard extends StatefulWidget {
  final Apartment apartment;
  final VoidCallback onTap;

  const ApartmentCard({
    super.key,
    required this.apartment,
    required this.onTap,
  });

  @override
  State<ApartmentCard> createState() => _ApartmentCardState();
}

class _ApartmentCardState extends State<ApartmentCard>
    with SingleTickerProviderStateMixin {
  bool _isFavorite = false;
  late final AnimationController _heartController;
  late final Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(_heartController);
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _heartController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final apt = widget.apartment;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: context.borderColor.withValues(alpha: 0.7),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDark ? 0.45 : 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image Section with Badges ──
                Stack(
                  children: [
                    Hero(
                      tag: 'apartment_${apt.id}',
                      child: Container(
                        height: 205,
                        width: double.infinity,
                        color: context.cardColor,
                        child: apt.images.isNotEmpty
                            ? Image.network(
                                apt.images[0],
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _ImagePlaceholder(color: context.cardColor),
                              )
                            : _ImagePlaceholder(color: context.cardColor),
                      ),
                    ),

                    // Top Gradient Shadow
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // ── Price Badge ──
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.9),
                          borderRadius: AppRadius.pillBr,
                          border: Border.all(
                            color: context.accentColor.withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${apt.monthlyPrice.round()} جنية',
                              style: TextStyle(
                                color: context.accentColor,
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

                    // ── Wishlist Heart Button ──
                    Positioned(
                      top: 12,
                      left: 14,
                      child: GestureDetector(
                        onTap: _toggleFavorite,
                        child: ScaleTransition(
                          scale: _heartScale,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Icon(
                              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: _isFavorite ? const Color(0xFFEF4444) : Colors.white,
                              size: 19,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── City & Rating Badge on bottom of image ──
                    Positioned(
                      bottom: 12,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: AppRadius.pillBr,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_rounded, size: 12, color: context.accentColor),
                            const SizedBox(width: 4),
                            Text(
                              apt.city,
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              apt.title,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              Icon(Icons.star_rounded, size: 16, color: context.accentColor),
                              const SizedBox(width: 2),
                              Text(
                                '4.9',
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // ── Specs Row ──
                      Row(
                        children: [
                          _SpecChip(
                            icon: Icons.bed_rounded,
                            value: '${apt.bedrooms} غرف',
                          ),
                          const SizedBox(width: 8),
                          _SpecChip(
                            icon: Icons.bathtub_rounded,
                            value: '${apt.bathrooms} حمام',
                          ),
                          const SizedBox(width: 8),
                          _SpecChip(
                            icon: Icons.square_foot_rounded,
                            value: '${apt.area.round()} م²',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Address & Owner Divider ──
                      Container(
                        height: 1,
                        color: context.borderColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 10),

                      // ── Address & Host Row ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  color: context.textSecondary,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    apt.address,
                                    style: TextStyle(
                                      color: context.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: context.accentColor.withValues(alpha: 0.2),
                                child: Icon(Icons.person, size: 12, color: context.accentColor),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                apt.ownerName.isNotEmpty ? apt.ownerName : 'المالك',
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.accentColor, size: 14),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
