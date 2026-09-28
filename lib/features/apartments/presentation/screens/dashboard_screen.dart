import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/empty_state.dart';
import 'package:sakani/core/widgets/section_header.dart';
import 'package:sakani/core/widgets/luxury_nav_bar.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_cubit.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_state.dart';
import 'package:sakani/features/apartments/presentation/widgets/owner_apartment_item.dart';
import 'package:sakani/features/apartments/presentation/widgets/owner_stats_overview.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/bookings/presentation/providers/booking_provider.dart';
import 'package:sakani/features/bookings/presentation/widgets/owner_booking_card.dart';
import 'package:sakani/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:sakani/features/settings/presentation/screens/settings_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _currentIndex = 0;
  String _bookingFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthCubit>().currentUser;
      if (user != null) {
        context.read<ApartmentCubit>().loadOwnerApartments(user.uid);
        context.read<BookingProvider>().getOwnerBookings(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['لوحة التحكم', 'عقاراتي', 'إدارة الحجوزات', 'المحادثات', 'الإعدادات'];

    final pages = [
      _buildOverviewTab(),
      _buildApartmentsTab(),
      _buildBookingsTab(),
      const ChatListScreen(isEmbedded: true),
      const SettingsScreen(isEmbedded: true),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          titles[_currentIndex],
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (_currentIndex == 0 || _currentIndex == 1)
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: context.accentColor),
              onPressed: () => Navigator.pushNamed(context, '/add-apartment'),
              tooltip: 'إضافة عقار جديد',
            ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/add-apartment'),
              backgroundColor: context.accentColor,
              foregroundColor: const Color(0xFF080C14),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة عقار', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildOverviewTab() {
    return BlocBuilder<ApartmentCubit, ApartmentState>(
      builder: (context, aptState) {
        final apartments = aptState.ownerApartments;
        final total = apartments.length;
        final available = apartments.where((a) => a.isAvailable).length;

        return Consumer<BookingProvider>(
          builder: (context, bookProv, _) {
            final bookings = bookProv.ownerBookings;
            final activeBookings = bookings.where((b) => b.status == 'مقبول' || b.status == 'نشط').length;
            final totalRevenue = bookings
                .where((b) => b.status == 'مقبول' || b.status == 'نشط' || b.status == 'مكتمل')
                .fold<double>(0.0, (sum, b) => sum + b.totalAmount);

            return RefreshIndicator(
              onRefresh: () async {
                final user = context.read<AuthCubit>().currentUser;
                if (user != null) {
                  context.read<ApartmentCubit>().loadOwnerApartments(user.uid);
                  await bookProv.getOwnerBookings(user.uid);
                }
              },
              child: ListView(
                padding: const EdgeInsets.only(top: 16, bottom: 96),
                children: [
                  OwnerStatsOverview(
                    totalProperties: total,
                    availableProperties: available,
                    activeBookings: activeBookings,
                    estimatedRevenue: totalRevenue,
                  ),
                  const SizedBox(height: 20),

                  // Quick Action Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/add-apartment'),
                            icon: const Icon(Icons.add_home_rounded, size: 18),
                            label: const Text('إضافة عقار جديد'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _currentIndex = 1),
                            icon: const Icon(Icons.apartment_rounded, size: 18),
                            label: const Text('عرض عقاراتي'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent bookings
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SectionHeader(title: 'أحدث طلبات الحجز'),
                  ),
                  const SizedBox(height: 8),

                  if (bookings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: EmptyState(
                        icon: Icons.event_busy_rounded,
                        title: 'لا توجد طلبات حجز بعد',
                        subtitle: 'ستظهر طلبات المستأجرين هنا فور إرسالها',
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: bookings.take(3).length,
                      itemBuilder: (context, index) {
                        final b = bookings[index];
                        return OwnerBookingCard(
                          booking: b,
                          onAccept: () => bookProv.updateBookingStatus(b.id, 'مقبول'),
                          onCancel: () => bookProv.updateBookingStatus(b.id, 'ملغي'),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildApartmentsTab() {
    return BlocBuilder<ApartmentCubit, ApartmentState>(
      builder: (context, state) {
        final apartments = state.ownerApartments;
        final user = context.read<AuthCubit>().currentUser;

        return RefreshIndicator(
          onRefresh: () async {
            if (user != null) {
              context.read<ApartmentCubit>().loadOwnerApartments(user.uid);
            }
          },
          child: apartments.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 40),
                    const EmptyState(
                      icon: Icons.holiday_village_outlined,
                      title: 'لم تقم بإضافة عقارات بعد',
                      subtitle: 'اضغط على زر "إضافة عقار" لنشر شقتك السكنية الأولى والبدء في استقبال المستأجرين',
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/add-apartment'),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('إضافة عقار الآن'),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: apartments.length,
                  itemBuilder: (context, index) {
                    final apt = apartments[index];
                    return OwnerApartmentItem(
                      apartment: apt,
                      onToggleAvailability: (_) {
                        context.read<ApartmentCubit>().toggleAvailability(apt.id, apt.isAvailable);
                      },
                      onDelete: () => _confirmDelete(context, apt.id, apt.title),
                      onTap: () {
                        final model = apt is ApartmentModel ? apt : ApartmentModel.fromEntity(apt);
                        Navigator.pushNamed(
                          context,
                          '/apartment-detail',
                          arguments: model,
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String id, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBr),
        title: const Text('حذف العقار', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('هل أنت متأكد من حذف "$title"؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ApartmentCubit>().deleteApartment(id);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return Consumer<BookingProvider>(
      builder: (context, bookProv, _) {
        final allBookings = bookProv.ownerBookings;
        final filtered = _bookingFilter == 'الكل'
            ? allBookings
            : allBookings.where((b) => b.status == _bookingFilter).toList();

        final filterOptions = ['الكل', 'قيد الانتظار', 'نشط', 'مقبول', 'مكتمل', 'ملغي'];

        return Column(
          children: [
            // Filter chips
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: filterOptions.length,
                itemBuilder: (context, index) {
                  final opt = filterOptions[index];
                  final isSelected = _bookingFilter == opt;

                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(opt),
                      selected: isSelected,
                      selectedColor: context.accentColor.withValues(alpha: 0.18),
                      backgroundColor: context.cardColor,
                      labelStyle: TextStyle(
                        color: isSelected ? context.accentColor : context.textSecondary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                        fontSize: 13,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBr),
                      onSelected: (val) {
                        if (val) setState(() => _bookingFilter = opt);
                      },
                    ),
                  );
                },
              ),
            ),

            // Bookings List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final user = context.read<AuthCubit>().currentUser;
                  if (user != null) {
                    await bookProv.getOwnerBookings(user.uid);
                  }
                },
                child: filtered.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 60),
                          EmptyState(
                            icon: Icons.event_busy_rounded,
                            title: 'لا توجد حجوزات في هذا التصنيف',
                            subtitle: 'اختر تصنيفاً آخر أو انتظر طلبات جديدة',
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 96),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final b = filtered[index];
                          return OwnerBookingCard(
                            booking: b,
                            onAccept: () => bookProv.updateBookingStatus(b.id, 'مقبول'),
                            onCancel: () => bookProv.updateBookingStatus(b.id, 'ملغي'),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNav() {
    final bookings = context.watch<BookingProvider>().ownerBookings;
    final pendingCount = bookings.where((b) => b.status == 'قيد الانتظار').length;

    return LuxuryNavBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      items: [
        const LuxuryNavItem(
          selectedIcon: Icons.dashboard_rounded,
          unselectedIcon: Icons.dashboard_outlined,
          label: 'الرئيسية',
        ),
        const LuxuryNavItem(
          selectedIcon: Icons.apartment_rounded,
          unselectedIcon: Icons.apartment_outlined,
          label: 'عقاراتي',
        ),
        LuxuryNavItem(
          selectedIcon: Icons.calendar_month_rounded,
          unselectedIcon: Icons.calendar_month_outlined,
          label: 'الحجوزات',
          badgeCount: pendingCount > 0 ? pendingCount : null,
        ),
        const LuxuryNavItem(
          selectedIcon: Icons.chat_bubble_rounded,
          unselectedIcon: Icons.chat_bubble_outline_rounded,
          label: 'المحادثات',
        ),
        const LuxuryNavItem(
          selectedIcon: Icons.person_rounded,
          unselectedIcon: Icons.person_outline_rounded,
          label: 'حسابي',
        ),
      ],
    );
  }
}
