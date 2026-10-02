// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/staggered_entrance.dart';
import 'package:sakani/core/widgets/app_cached_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/localization/app_localizations.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/apartments/presentation/cubit/wishlist_cubit.dart';

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
  late final AnimationController _heartController;
  late final Animation<double> _heartScale;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 0.85), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 30),
    ]).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    context.read<WishlistCubit>().toggleFavorite(widget.apartment.id);
    _heartController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().lang;
    final tr = AppLocalizations(lang);
    final apt = widget.apartment;
    final isFavorite = context.watch<WishlistCubit>().isFavorite(apt.id);
    final isDark = context.isDark;
    final hasMultipleImages = apt.images.length > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: BouncingTap(
        scaleFactor: 0.98,
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : context.borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              if (isDark)
                BoxShadow(
                  color: context.accentColor.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Interactive Image Section with Badges ──
              Stack(
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    color: context.cardColor,
                    child: hasMultipleImages
                        ? PageView.builder(
                            itemCount: apt.images.length,
                            onPageChanged: (i) =>
                                setState(() => _currentImageIndex = i),
                            itemBuilder: (context, index) {
                              return AppCachedImage(
                                imageUrl: apt.images[index],
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : AppCachedImage(
                            imageUrl:
                                apt.images.isNotEmpty ? apt.images[0] : '',
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),

                  // Top gradient for badge contrast
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.65),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom gradient for location and dot contrast
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 70,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.75),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Verified / Featured Badge ──
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.accentColor.withValues(alpha: 0.6),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 13,
                            color: context.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lang == 'ar' ? 'موثق ومميز' : 'Verified VIP',
                            style: TextStyle(
                              color: context.accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
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
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite
                                ? const Color(0xFFEF4444)
                                : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── City & Address on Bottom Right ──
                  Positioned(
                    bottom: 12,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: context.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            apt.city,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Mini Indicator Dots (Center Bottom) ──
                  if (hasMultipleImages)
                    Positioned(
                      bottom: 14,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          apt.images.length.clamp(0, 6),
                          (dotIndex) {
                            final isActive = _currentImageIndex == dotIndex;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              margin: const EdgeInsets.symmetric(horizontal: 2.5),
                              width: isActive ? 14 : 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // ── Photo Counter Badge (Bottom Left) ──
                  if (hasMultipleImages)
                    Positioned(
                      bottom: 12,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_library_outlined,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_currentImageIndex + 1}/${apt.images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
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
                    // Title and Rating
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            apt.title,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: context.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 15,
                                color: context.accentColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '4.9',
                                style: TextStyle(
                                  color: context.accentColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ── Specs Row ──
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _ModernSpecPill(
                          icon: Icons.king_bed_rounded,
                          value: '${apt.bedrooms} ${lang == 'ar' ? 'غرف' : 'Beds'}',
                        ),
                        _ModernSpecPill(
                          icon: Icons.bathtub_rounded,
                          value: '${apt.bathrooms} ${lang == 'ar' ? 'حمام' : 'Baths'}',
                        ),
                        _ModernSpecPill(
                          icon: Icons.straighten_rounded,
                          value: '${apt.area.round()} ${lang == 'ar' ? 'م²' : 'm²'}',
                        ),
                        _ModernSpecPill(
                          icon: Icons.access_time_rounded,
                          value: apt.availableRentTypes.isNotEmpty
                              ? (apt.availableRentTypes.first == 'يومي'
                                  ? tr.tr('daily')
                                  : (apt.availableRentTypes.first == 'سنوي'
                                      ? tr.tr('yearly')
                                      : tr.tr('monthly')))
                              : tr.tr('monthly'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Divider
                    Container(
                      height: 1,
                      color: context.borderColor.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 12),

                    // ── Price & Host Row ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang == 'ar' ? 'سعر الإيجار' : 'Rental Price',
                              style: TextStyle(
                                fontSize: 10,
                                color: context.textSecondary.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '${apt.monthlyPrice.round()}',
                                  style: GoogleFonts.outfit(
                                    color: context.accentColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tr.tr('currency'),
                                  style: TextStyle(
                                    color: context.accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  apt.availableRentTypes.contains("يومي") &&
                                          !apt.availableRentTypes.contains(
                                            "شهري",
                                          )
                                      ? ' / ${tr.tr('daily')}'
                                      : apt.availableRentTypes.contains(
                                              "سنوي",
                                            ) &&
                                            !apt.availableRentTypes.contains(
                                              "شهري",
                                            )
                                      ? ' / ${tr.tr('yearly')}'
                                      : ' / ${tr.tr('monthly')}',
                                  style: TextStyle(
                                    color: context.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Host avatar & details
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: context.borderColor.withValues(alpha: 0.8),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: context.accentColor.withValues(
                                  alpha: 0.2,
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 14,
                                  color: context.accentColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                apt.ownerName.isNotEmpty
                                    ? apt.ownerName
                                    : (lang == 'ar' ? 'مالك موثق' : 'Verified Host'),
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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
    );
  }
}

// ── Modern Spec Pill ──
class _ModernSpecPill extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ModernSpecPill({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.5),
          width: 0.8,
        ),
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
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
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
              Icons.apartment_rounded,
              size: 46,
              color: context.accentColor.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 6),
            Text(
              'صورة الشقة قيد التحديث',
              style: TextStyle(
                color: context.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
