import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/glass_card.dart';
import 'package:sakani/features/apartments/domain/entities/apartment_entity.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_cubit.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_state.dart';
import 'package:sakani/core/localization/app_localizations.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';

/// شاشة الخريطة التفاعلية واستكشاف الشقق جغرافياً
class ApartmentsMapScreen extends StatefulWidget {
  const ApartmentsMapScreen({super.key});

  @override
  State<ApartmentsMapScreen> createState() => _ApartmentsMapScreenState();
}

class _ApartmentsMapScreenState extends State<ApartmentsMapScreen> {
  String _selectedCity = 'الكل';
  ApartmentEntity? _selectedApartment;

  final List<String> _cities = [
    'الكل',
    'القاهرة',
    'الجيزة',
    'الإسكندرية',
    'الساحل الشمالي',
    'الشيخ زايد',
    'التجمع الخامس',
  ];

  String _getCityDisplay(String city, AppLocalizations tr) {
    switch (city) {
      case 'الكل':
        return tr.tr('all');
      case 'القاهرة':
        return tr.tr('cairo');
      case 'الجيزة':
        return tr.tr('giza');
      case 'الإسكندرية':
        return tr.tr('alexandria');
      case 'الساحل الشمالي':
        return tr.tr('northCoast');
      case 'الشيخ زايد':
        return tr.tr('zayed');
      case 'التجمع الخامس':
        return tr.tr('tagamoa');
      default:
        return city;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final lang = context.watch<LocaleProvider>().lang;
    final tr = AppLocalizations(lang);

    return Scaffold(
      backgroundColor: context.bgColor,
      body: BlocBuilder<ApartmentCubit, ApartmentState>(
        builder: (context, state) {
          final allApts = state.apartments;
          final filteredApts = _selectedCity == 'الكل'
              ? allApts
              : allApts.where((a) => (a.city.contains(_selectedCity) || a.address.contains(_selectedCity))).toList();

          return Stack(
            children: [
              // ── 1. Interactive Luxury Vector Map Canvas ──
              Positioned.fill(
                child: _LuxuryMapCanvas(
                  apartments: filteredApts,
                  selectedApartment: _selectedApartment,
                  onSelectApartment: (apt) {
                    setState(() {
                      _selectedApartment = apt;
                    });
                  },
                ),
              ),

              // ── 2. Top Header Bar & Search/Filter ──
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          // Back Button
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              border: Border.all(color: context.borderColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                context.isArabic ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_rounded,
                                size: 18,
                                color: context.textPrimary,
                              ),
                              onPressed: () => Navigator.pop(context),
                              tooltip: tr.tr('close'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Search / Title Bar
                          Expanded(
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: context.borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.search_rounded, color: context.accentColor, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      lang == 'ar'
                                          ? 'استكشف ${filteredApts.length} شقة على الخريطة'
                                          : 'Explore ${filteredApts.length} apartments on map',
                                      style: GoogleFonts.tajawal(
                                        color: context.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: context.accentColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'GPS',
                                      style: GoogleFonts.tajawal(
                                        color: context.accentColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // City Filter Chips
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _cities.length,
                          itemBuilder: (context, index) {
                            final city = _cities[index];
                            final isSelected = _selectedCity == city;

                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                label: Text(_getCityDisplay(city, tr)),
                                selected: isSelected,
                                selectedColor: context.accentColor,
                                backgroundColor: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.88) : Colors.white.withValues(alpha: 0.92),
                                labelStyle: GoogleFonts.tajawal(
                                  color: isSelected ? const Color(0xFF080C14) : context.textSecondary,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                side: BorderSide(
                                  color: isSelected ? context.accentColor : context.borderColor,
                                ),
                                onSelected: (val) {
                                  if (val) setState(() => _selectedCity = city);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 3. Floating Bottom Preview Card for Selected Apartment ──
              if (_selectedApartment != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: _ApartmentMapCard(
                    apartment: _selectedApartment!,
                    onClose: () => setState(() => _selectedApartment = null),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// رسم خريطة فكتور تفاعلية فاخرة مع دبابيس الأسعار
class _LuxuryMapCanvas extends StatelessWidget {
  final List<ApartmentEntity> apartments;
  final ApartmentEntity? selectedApartment;
  final ValueChanged<ApartmentEntity> onSelectApartment;

  const _LuxuryMapCanvas({
    required this.apartments,
    required this.selectedApartment,
    required this.onSelectApartment,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Container(
      color: isDark ? const Color(0xFF080C14) : const Color(0xFFE2E8F0),
      child: CustomPaint(
        painter: _MapGridPainter(isDark: isDark),
        child: Stack(
          children: [
            // Center Radar Ambient Wave
            Center(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.accentColor.withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                width: 480,
                height: 480,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.accentColor.withValues(alpha: 0.04),
                    width: 1.5,
                  ),
                ),
              ),
            ),

            // Distributed Pins for each Apartment
            ...List.generate(apartments.length, (index) {
              final apt = apartments[index];
              final isSelected = selectedApartment?.id == apt.id;

              // Generate pseudo-coordinates distributed over the map
              final double topOffset = 180.0 + ((index * 83) % 420);
              final double leftOffset = 30.0 + ((index * 117) % 280);

              return Positioned(
                top: topOffset,
                left: leftOffset,
                child: GestureDetector(
                  onTap: () => onSelectApartment(apt),
                  child: AnimatedScale(
                    scale: isSelected ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: _MapPricePin(
                      price: apt.monthlyPrice > 0 ? apt.monthlyPrice : apt.dailyPrice,
                      isSelected: isSelected,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// دبوس سعر الشقة على الخريطة
class _MapPricePin extends StatelessWidget {
  final double price;
  final bool isSelected;

  const _MapPricePin({
    required this.price,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? context.accentColor : (context.isDark ? const Color(0xFF0F172A) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.white : context.accentColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? context.accentColor.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.3),
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hotel_rounded,
            size: 13,
            color: isSelected ? const Color(0xFF080C14) : context.accentColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${(price / 1000).toStringAsFixed(1)}k ج.م',
            style: GoogleFonts.outfit(
              color: isSelected ? const Color(0xFF080C14) : context.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// كارت معاينة الشقة العائم أسفل الخريطة
class _ApartmentMapCard extends StatelessWidget {
  final ApartmentEntity apartment;
  final VoidCallback onClose;

  const _ApartmentMapCard({
    required this.apartment,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().lang;
    final tr = AppLocalizations(lang);
    final image = apartment.images.isNotEmpty ? apartment.images.first : '';

    return GlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: 22,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Image Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: image,
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) => Container(color: context.surfaceColor),
                          errorWidget: (ctx, url, err) => Container(
                            color: context.surfaceColor,
                            child: const Icon(Icons.home_work_outlined),
                          ),
                        )
                      : Container(color: context.surfaceColor),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            apartment.title,
                            style: GoogleFonts.tajawal(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: onClose,
                          child: Icon(Icons.close_rounded, size: 18, color: context.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: context.accentColor),
                        const SizedBox(width: 3),
                        Text(
                          apartment.city,
                          style: GoogleFonts.tajawal(fontSize: 11, color: context.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
                        Text(
                          ' 4.9',
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: context.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${apartment.monthlyPrice > 0 ? apartment.monthlyPrice.round() : apartment.dailyPrice.round()} ${tr.tr('currency')}',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: context.accentColor,
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.accentColor,
                                foregroundColor: const Color(0xFF080C14),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                final model = apartment is ApartmentModel
                                    ? apartment as ApartmentModel
                                    : ApartmentModel.fromEntity(apartment);
                                Navigator.pushNamed(context, '/booking', arguments: model);
                              },
                              child: Text(
                                tr.tr('instantBook'),
                                style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w800),
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
        ],
      ),
    );
  }
}

/// رسام شبكة خطوط الخريطة الفاخرة
class _MapGridPainter extends CustomPainter {
  final bool isDark;
  _MapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
