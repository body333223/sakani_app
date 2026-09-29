// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';
import 'package:sakani/core/widgets/app_cached_image.dart';
import 'package:sakani/core/widgets/gradient_button.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakani/features/chat/presentation/providers/chat_provider.dart';
import 'package:sakani/features/chat/presentation/screens/chat_screen.dart';

class ApartmentDetailScreen extends StatefulWidget {
  final Apartment apartment;

  const ApartmentDetailScreen({super.key, required this.apartment});

  @override
  State<ApartmentDetailScreen> createState() => _ApartmentDetailScreenState();
}

class _ApartmentDetailScreenState extends State<ApartmentDetailScreen> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final apt = widget.apartment;
    final images = apt.images;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          // ── Scrollable Body ──
          CustomScrollView(
            slivers: [
              // ── Image Header with PageView ──
              SliverAppBar(
                expandedHeight: 330,
                pinned: true,
                elevation: 0,
                backgroundColor: context.bgColor,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      child: IconButton(
                        icon: Icon(
                          _isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _isFavorite
                              ? const Color(0xFFEF4444)
                              : Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() => _isFavorite = !_isFavorite);
                          AppSnackbar.show(
                            context,
                            message: _isFavorite
                                ? 'تمت الإضافة للمفضلة'
                                : 'تمت الإزالة من المفضلة',
                            type: _isFavorite
                                ? ToastType.success
                                : ToastType.info,
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      child: IconButton(
                        icon: const Icon(
                          Icons.share_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          AppSnackbar.show(
                            context,
                            message: 'تم نسخ رابط الشقة للمشاركة',
                            type: ToastType.info,
                          );
                        },
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'apartment_${apt.id}',
                        child: images.isNotEmpty
                            ? PageView.builder(
                                itemCount: images.length,
                                onPageChanged: (i) =>
                                    setState(() => _currentImageIndex = i),
                                itemBuilder: (context, index) {
                                  return AppCachedImage(
                                    imageUrl: images[index],
                                    fit: BoxFit.cover,
                                  );
                                },
                              )
                            : const AppCachedImage(
                                imageUrl: '',
                                fit: BoxFit.cover,
                              ),
                      ),

                      // Gradient Bottom Fade
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 90,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Page Indicator Counter
                      if (images.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: AppRadius.pillBr,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1} / ${images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Details Content ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status & Rating Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: apt.isAvailable
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.error.withValues(alpha: 0.15),
                              borderRadius: AppRadius.pillBr,
                              border: Border.all(
                                color: apt.isAvailable
                                    ? AppColors.success
                                    : AppColors.error,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: apt.isAvailable
                                        ? AppColors.success
                                        : AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  apt.isAvailable
                                      ? 'متاحة للحجز الآن'
                                      : 'محجوزة حالياً',
                                  style: TextStyle(
                                    color: apt.isAvailable
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: context.accentColor,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '4.95',
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                ' (28 تقييم)',
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        apt.title,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Location Row
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: context.accentColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${apt.city} - ${apt.address}',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Specifications Grid ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: context.isDark ? 0.3 : 0.05,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _SpecItem(
                              icon: Icons.king_bed_outlined,
                              label: 'الغرف',
                              value: '${apt.bedrooms}',
                            ),
                            _buildDivider(context),
                            _SpecItem(
                              icon: Icons.bathtub_outlined,
                              label: 'الحمامات',
                              value: '${apt.bathrooms}',
                            ),
                            _buildDivider(context),
                            _SpecItem(
                              icon: Icons.straighten_outlined,
                              label: 'المساحة',
                              value: '${apt.area.round()} م²',
                            ),
                            _buildDivider(context),
                            _SpecItem(
                              icon: Icons.group_outlined,
                              label: 'الضيوف',
                              value: '${apt.maxGuests}',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Description ──
                      Text(
                        'عن هذا السكن',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        apt.description,
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Amenities Section ──
                      if (apt.amenities.isNotEmpty) ...[
                        Text(
                          'المرافق والخدمات المتاحة',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: apt.amenities.map((amenity) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getAmenityIcon(amenity),
                                    size: 16,
                                    color: context.accentColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    amenity,
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Host Card ──
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: context.accentColor.withValues(
                                alpha: 0.15,
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                size: 28,
                                color: context.accentColor,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    apt.ownerName.isNotEmpty
                                        ? apt.ownerName
                                        : 'مالك السكن',
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.verified_rounded,
                                        size: 14,
                                        color: context.accentColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'مالك معتمد وموثق',
                                        style: TextStyle(
                                          color: context.accentColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
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
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Floating Bottom Booking Bar ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(top: BorderSide(color: context.borderColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Price Tag
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'الإيجار الشهري',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${apt.monthlyPrice.round()}',
                              style: TextStyle(
                                color: context.accentColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              ' ج.م',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Chat with Host Icon Button
                  IconButton(
                    tooltip: 'محادثة المالك',
                    onPressed: () => _openChat(context),
                    icon: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.accentColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: context.accentColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Book Now Button
                  Expanded(
                    flex: 6,
                    child: GradientButton(
                      text: 'احجز الآن',
                      height: 48,
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/booking',
                          arguments: apt,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    final user = authCubit.currentUser ?? context.read<AuthProvider>().user;
    if (user == null) {
      AppSnackbar.show(
        context,
        message: 'يرجى تسجيل الدخول أولاً للمحادثة',
        type: ToastType.warning,
      );
      return;
    }

    final chatProv = context.read<ChatProvider>();
    final room = await chatProv.createRoom(
      apartmentId: widget.apartment.id,
      apartmentTitle: widget.apartment.title,
      tenantId: user.uid,
      tenantName: user.name,
      ownerId: widget.apartment.ownerId,
      ownerName: widget.apartment.ownerName,
    );

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(room: room)),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: context.borderColor.withValues(alpha: 0.6),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    if (amenity.contains('واي فاي')) return Icons.wifi_rounded;
    if (amenity.contains('تكييف')) return Icons.ac_unit_rounded;
    if (amenity.contains('موقف')) return Icons.local_parking_rounded;
    if (amenity.contains('مطبخ')) return Icons.kitchen_rounded;
    if (amenity.contains('غسالة')) return Icons.local_laundry_service_rounded;
    if (amenity.contains('تلفزيون')) return Icons.tv_rounded;
    if (amenity.contains('مسبح')) return Icons.pool_rounded;
    if (amenity.contains('صالة')) return Icons.fitness_center_rounded;
    if (amenity.contains('مصعد')) return Icons.elevator_rounded;
    if (amenity.contains('أمن')) return Icons.shield_rounded;
    if (amenity.contains('حديقة')) return Icons.park_rounded;
    return Icons.check_circle_outline_rounded;
  }
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: context.accentColor, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: context.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final Color color;
  const _ImagePlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Icon(
          Icons.home_work_outlined,
          size: 56,
          color: context.accentColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
