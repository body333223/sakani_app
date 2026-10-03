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
import 'package:sakani/features/bookings/data/models/booking_model.dart';
import 'package:sakani/features/bookings/presentation/providers/booking_provider.dart';
import 'package:sakani/features/bookings/presentation/widgets/owner_booking_card.dart';
import 'package:sakani/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:sakani/features/settings/presentation/screens/profile_screen.dart';
import 'package:sakani/core/localization/app_localizations.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/services/push_notification_service.dart';
import 'package:sakani/features/contracts/data/services/contract_service.dart';
import 'package:sakani/features/contracts/presentation/screens/digital_contract_screen.dart';

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

  Future<void> _handleAcceptBooking(Booking b) async {
    // 1. Update booking status
    await context.read<BookingProvider>().updateBookingStatus(b.id, 'مقبول');

    // 2. Mark apartment as occupied with start & end dates
    if (mounted) {
      await context.read<ApartmentCubit>().setOccupancy(
        b.apartmentId,
        from: b.startDate,
        until: b.endDate,
        isAvailable: false,
      );

      // 3. Auto-generate official certified digital rental contract with National ID & SHA-256 seal
      final contract = await ContractService().generateOrGetContract(
        booking: b,
      );

      // 4. Send Instant Push Notification with Audio Alert to Tenant's phone
      if (mounted) {
        await PushNotificationService().notifyTenantBookingAccepted(
          context: context,
          tenantId: b.tenantId,
          apartmentTitle: b.apartmentTitle,
          contractId: contract.id,
        );
      }

      // 5. Present official contract confirmation modal with direct view/export action
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBr),
          title: Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.success, size: 28),
              const SizedBox(width: 8),
              Text(
                'تم قبول الحجز وتوثيق العقد',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تم إصدار وتوثيق عقد إيجار رسمي إلكتروني برقم قومي وبصمة مشفرة SHA-256 لحفظ حقوق الطرفين قانونياً.',
                style: GoogleFonts.tajawal(fontSize: 13, color: context.textPrimary, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: AppRadius.mdBr,
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('رقم العقد: ${contract.id}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.gold)),
                    const SizedBox(height: 2),
                    Text('الحالة: معتمد ومحمي بحساب الضمان (Escrow)', style: GoogleFonts.tajawal(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('الرقم القومي للمستأجر: ${contract.tenantNationalId}', style: GoogleFonts.outfit(fontSize: 11, color: context.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إغلاق', style: GoogleFonts.tajawal(color: context.textSecondary)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DigitalContractScreen(contract: contract),
                  ),
                );
              },
              icon: const Icon(Icons.description_rounded, size: 16),
              label: Text('عرض وثيقة العقد 📄', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: const Color(0xFF080C14),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleRejectBooking(Booking b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
        title: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.error),
            SizedBox(width: 8),
            Text('رفض طلب الحجز', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text('هل أنت متأكد من رغبتك في رفض طلب حجز ${b.apartmentTitle} للمستأجر ${b.tenantName}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('تراجع', style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تأكيد الرفض'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<BookingProvider>().updateBookingStatus(b.id, 'مرفوض');
      if (!mounted) return;
      await PushNotificationService().notifyTenantBookingRejected(
        context: context,
        tenantId: b.tenantId,
        apartmentTitle: b.apartmentTitle,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم رفض طلب الحجز (${b.apartmentTitle}) بنجاح'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().lang;
    final tr = AppLocalizations(lang);
    final isAr = lang == 'ar';

    final titles = [
      tr.tr('ownerDashboard'),
      tr.tr('myProperties'),
      tr.tr('manageBookings'),
      tr.tr('chats'),
      tr.tr('myAccount'),
    ];

    final pages = [
      _buildOverviewTab(tr),
      _buildApartmentsTab(tr),
      _buildBookingsTab(tr),
      const ChatListScreen(isEmbedded: true),
      const ProfileScreen(),
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
          IconButton(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: context.accentColor.withValues(alpha: 0.6)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isAr ? 'EN' : 'عربي',
                style: TextStyle(
                  color: context.accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            onPressed: () => context.read<LocaleProvider>().toggleLang(),
            tooltip: tr.tr('changeLanguage'),
          ),
          if (_currentIndex == 0 || _currentIndex == 1)
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: context.accentColor),
              onPressed: () => Navigator.pushNamed(context, '/add-apartment'),
              tooltip: tr.tr('addApartment'),
            ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(tr),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/add-apartment'),
              backgroundColor: context.accentColor,
              foregroundColor: const Color(0xFF080C14),
              icon: const Icon(Icons.add_rounded),
              label: Text(tr.tr('addApartment'), style: const TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildOverviewTab(AppLocalizations tr) {
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
                .fold<double>(0.0, (sum, b) => sum + (b.totalAmount - b.commissionAmount));
            final pendingRevenue = bookings
                .where((b) => b.status == 'قيد الانتظار')
                .fold<double>(0.0, (sum, b) => sum + (b.totalAmount - b.commissionAmount));

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
                    pendingRevenue: pendingRevenue,
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
                            label: Text(tr.tr('addApartment')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _currentIndex = 1),
                            icon: const Icon(Icons.apartment_rounded, size: 18),
                            label: Text(tr.tr('viewMyProperties')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent bookings
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SectionHeader(title: tr.tr('recentBookingRequests')),
                  ),
                  const SizedBox(height: 8),

                  if (bookings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: EmptyState(
                        icon: Icons.event_busy_rounded,
                        title: tr.tr('noBookingsYet'),
                        subtitle: tr.tr('noBookingsSubtitle'),
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
                          onAccept: () => _handleAcceptBooking(b),
                          onCancel: () => _handleRejectBooking(b),
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

  Widget _buildApartmentsTab(AppLocalizations tr) {
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
                    EmptyState(
                      icon: Icons.holiday_village_outlined,
                      title: tr.tr('noPropertiesYet'),
                      subtitle: tr.tr('noPropertiesSubtitle'),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/add-apartment'),
                        icon: const Icon(Icons.add_rounded),
                        label: Text(tr.tr('addPropertyNow')),
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
                      onUpdatePrice: (newPrice) {
                        context.read<ApartmentCubit>().updatePrice(apt.id, newPrice);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tr.tr('propertyPriceUpdated', [newPrice.round().toString()])),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onDelete: () => _confirmDelete(context, apt.id, apt.title, tr),
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

  void _confirmDelete(BuildContext context, String id, String title, AppLocalizations tr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBr),
        title: Text(tr.tr('deleteProperty'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(tr.tr('deleteConfirm', [title])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr.tr('cancel'), style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ApartmentCubit>().deleteApartment(id);
            },
            child: Text(tr.tr('delete')),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab(AppLocalizations tr) {
    return Consumer<BookingProvider>(
      builder: (context, bookProv, _) {
        final allBookings = bookProv.ownerBookings;
        final filtered = _bookingFilter == 'الكل'
            ? allBookings
            : allBookings.where((b) {
                if (_bookingFilter == 'ملغي') {
                  return b.status == 'ملغي' || b.status == 'مرفوض';
                }
                return b.status == _bookingFilter;
              }).toList();

        final filterOptions = [
          {'key': 'الكل', 'label': tr.tr('filterAll')},
          {'key': 'قيد الانتظار', 'label': tr.tr('filterPending')},
          {'key': 'نشط', 'label': tr.tr('filterActive')},
          {'key': 'مقبول', 'label': tr.tr('filterAccepted')},
          {'key': 'مكتمل', 'label': tr.tr('filterCompleted')},
          {'key': 'ملغي', 'label': tr.tr('filterCancelled')},
        ];

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
                  final isSelected = _bookingFilter == opt['key'];

                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(opt['label']!),
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
                        if (val) setState(() => _bookingFilter = opt['key']!);
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
                        children: [
                          const SizedBox(height: 60),
                          EmptyState(
                            icon: Icons.event_busy_rounded,
                            title: tr.tr('noBookingsCategory'),
                            subtitle: tr.tr('noBookingsCategorySub'),
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
                            onAccept: () => _handleAcceptBooking(b),
                            onCancel: () => _handleRejectBooking(b),
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

  Widget _buildBottomNav(AppLocalizations tr) {
    final bookings = context.watch<BookingProvider>().ownerBookings;
    final pendingCount = bookings.where((b) => b.status == 'قيد الانتظار').length;

    return LuxuryNavBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      items: [
        LuxuryNavItem(
          selectedIcon: Icons.dashboard_rounded,
          unselectedIcon: Icons.dashboard_outlined,
          label: tr.tr('home'),
        ),
        LuxuryNavItem(
          selectedIcon: Icons.apartment_rounded,
          unselectedIcon: Icons.apartment_outlined,
          label: tr.tr('myProperties'),
        ),
        LuxuryNavItem(
          selectedIcon: Icons.calendar_month_rounded,
          unselectedIcon: Icons.calendar_month_outlined,
          label: tr.tr('manageBookings'),
          badgeCount: pendingCount > 0 ? pendingCount : null,
        ),
        LuxuryNavItem(
          selectedIcon: Icons.chat_bubble_rounded,
          unselectedIcon: Icons.chat_bubble_outline_rounded,
          label: tr.tr('chats'),
        ),
        LuxuryNavItem(
          selectedIcon: Icons.account_circle_rounded,
          unselectedIcon: Icons.account_circle_outlined,
          label: 'ملفي',
        ),
      ],
    );
  }
}
