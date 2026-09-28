import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakani/features/chat/presentation/providers/chat_provider.dart';
import 'package:sakani/core/widgets/glass_card.dart';
import 'package:sakani/core/widgets/section_header.dart';
import 'package:sakani/features/chat/presentation/screens/chat_screen.dart';

class ApartmentDetailScreen extends StatelessWidget {
  final Apartment apartment;
  const ApartmentDetailScreen({super.key, required this.apartment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar with Image ──
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'apartment_${apartment.id}',
                child: Container(
                  color: context.cardColor,
                  child: apartment.images.isNotEmpty
                      ? Image.network(
                          apartment.images[0],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, _, _) =>
                              _ImagePlaceholder(color: context.cardColor),
                        )
                      : _ImagePlaceholder(color: context.cardColor),
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: context.bgColor.withValues(alpha: 0.8),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: context.textPrimary,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Status Badge ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: apartment.isAvailable
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.error.withValues(alpha: 0.12),
                          borderRadius: AppRadius.pillBr,
                          border: Border.all(
                            color: apartment.isAvailable
                                ? AppColors.success.withValues(alpha: 0.3)
                                : AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          apartment.isAvailable ? 'متاحة' : 'غير متاحة',
                          style: TextStyle(
                            color: apartment.isAvailable
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Title ──
                  Text(
                    apartment.title,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Location ──
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: context.accentColor,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${apartment.city} - ${apartment.address}',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (apartment.contactPhone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          color: context.accentColor,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          apartment.contactPhone,
                          style: TextStyle(
                            color: context.accentColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── Prices Card ──
                  StyledCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (apartment.availableRentTypes.contains('يومي'))
                              _PriceColumn(
                                label: 'يومي',
                                price: apartment.dailyPrice,
                              ),
                            if (apartment.availableRentTypes.contains('يومي') &&
                                (apartment.availableRentTypes.contains('شهري') ||
                                    apartment.availableRentTypes.contains('سنوي')))
                              Container(
                                width: 1,
                                height: 40,
                                color: context.borderColor,
                              ),
                            if (apartment.availableRentTypes.contains('شهري'))
                              _PriceColumn(
                                label: 'شهري',
                                price: apartment.monthlyPrice,
                              ),
                            if (apartment.availableRentTypes.contains('شهري') &&
                                apartment.availableRentTypes.contains('سنوي'))
                              Container(
                                width: 1,
                                height: 40,
                                color: context.borderColor,
                              ),
                            if (apartment.availableRentTypes.contains('سنوي'))
                              _PriceColumn(
                                label: 'سنوي',
                                price: apartment.yearlyPrice,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(color: context.borderColor),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _InfoChip(
                              icon: Icons.bed_rounded,
                              value: '${apartment.bedrooms} غرف',
                            ),
                            _InfoChip(
                              icon: Icons.bathtub_rounded,
                              value: '${apartment.bathrooms} حمامات',
                            ),
                            _InfoChip(
                              icon: Icons.square_foot_rounded,
                              value: '${apartment.area} م²',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Description ──
                  const SectionHeader(title: 'الوصف'),
                  Text(
                    apartment.description,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 14,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Amenities ──
                  const SectionHeader(title: 'الخدمات والمرافق'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: apartment.amenities.map((a) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: context.accentColor.withValues(alpha: 0.08),
                          borderRadius: AppRadius.pillBr,
                          border: Border.all(
                            color: context.accentColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: context.accentColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              a,
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ── Deposit Info ──
                  const SectionHeader(title: 'معلومات الإيداع'),
                  StyledCard(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.accentColor.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.shield_rounded,
                            color: context.accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تأمين: ${apartment.securityDeposit} ',
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'قابل للاسترداد',
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(top: BorderSide(color: context.borderColor)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: apartment.isAvailable
                        ? () => Navigator.pushNamed(
                              context,
                              '/booking',
                              arguments: apartment,
                            )
                        : null,
                    icon: const Icon(Icons.calendar_today_rounded, size: 20),
                    label: Text(apartment.isAvailable ? 'حجز الآن' : 'غير متوفرة حالياً'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final auth = context.read<AuthProvider>();
                    final chatProv = context.read<ChatProvider>();
                    final user = auth.user;
                    if (user == null) return;
                    final room = await chatProv.createRoom(
                      apartmentId: apartment.id,
                      apartmentTitle: apartment.title,
                      tenantId: user.uid,
                      tenantName: user.name,
                      ownerId: apartment.ownerId,
                      ownerName: apartment.ownerName,
                    );
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatScreen(room: room)),
                    );
                  },
                  icon: const Icon(Icons.message_outlined, size: 20),
                  label: const Text('محادثة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Price Column ──
class _PriceColumn extends StatelessWidget {
  final String label;
  final double price;

  const _PriceColumn({required this.label, required this.price});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$price [جنية]',
          style: TextStyle(
            color: context.accentColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: context.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

// ── Info Chip ──
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String value;

  const _InfoChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: context.accentColor, size: 18),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(color: context.textSecondary, fontSize: 13),
        ),
      ],
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
              size: 56,
              color: context.accentColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'لا توجد صورة',
              style: TextStyle(
                color: context.textSecondary.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
