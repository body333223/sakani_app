import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/localization/app_localizations.dart';
import 'package:sakani/core/widgets/shimmer_loading.dart';
import 'package:sakani/core/widgets/notifications_bottom_sheet.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_cubit.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_state.dart';
import 'package:sakani/features/apartments/presentation/widgets/apartment_card.dart';
import 'package:sakani/features/apartments/presentation/widgets/filter_bottom_sheet.dart';
import 'package:sakani/core/widgets/luxury_nav_bar.dart';
import 'package:sakani/features/apartments/presentation/cubit/wishlist_cubit.dart';
import 'package:sakani/features/apartments/presentation/screens/wishlist_screen.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_state.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakani/features/auth/data/services/auth_service.dart';
import 'package:sakani/features/bookings/presentation/screens/my_bookings_screen.dart';
import 'package:sakani/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';
import 'package:sakani/features/settings/presentation/screens/settings_screen.dart';
import 'package:sakani/core/widgets/staggered_entrance.dart';

class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchCtl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    context.read<ApartmentCubit>().loadApartments();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().lang;
    final tr = AppLocalizations(lang);
    final auth = context.watch<AuthProvider>();
    final authCubit = context.watch<AuthCubit>();
    final authState = authCubit.state;
    final user = authCubit.currentUser ??
        (authState is Authenticated ? authState.user : null) ??
        auth.user ??
        AuthService.currentUser;
    final userPhoto = user?.photoUrl;
    final userName = user?.name;
    final hasUserPhoto = userPhoto != null && userPhoto.isNotEmpty;
    final hasUserName = userName != null && userName.isNotEmpty;

    final List<Widget> pages = [
      _buildExploreTab(tr),
      WishlistScreen(onExplore: () => setState(() => _currentIndex = 0)),
      const MyBookingsScreen(isEmbedded: true),
      const ChatListScreen(isEmbedded: true),
      const SettingsScreen(isEmbedded: true),
    ];

    final List<String> titles = [
      tr.tr('appName'),
      tr.tr('wishlist'),
      tr.tr('myBookings'),
      tr.tr('chats'),
      tr.tr('myAccount'),
    ];

    return Scaffold(
      extendBody: true,
      appBar: _currentIndex == 0
          ? PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      // Brand & Greeting
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              hasUserName
                                  ? '${tr.tr('welcome')} ${userName.split(' ').first}'
                                  : tr.tr('appName'),
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tr.tr('appTagline'),
                              style: TextStyle(
                                color: context.accentColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Language Toggle
                      BouncingTap(
                        onTap: () => context.read<LocaleProvider>().toggleLang(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.borderColor,
                            ),
                          ),
                          child: Text(
                            lang == 'ar' ? 'EN' : 'عربي',
                            style: TextStyle(
                              color: context.accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Notifications
                      BouncingTap(
                        onTap: () => NotificationsBottomSheet.show(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.borderColor),
                          ),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            color: context.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Profile Avatar
                      GestureDetector(
                        onTap: () => setState(() => _currentIndex = 4),
                        child: Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: context.accentColor, width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: 17,
                            backgroundColor: context.surfaceColor,
                            backgroundImage: hasUserPhoto
                                ? (userPhoto.startsWith('http')
                                    ? CachedNetworkImageProvider(userPhoto)
                                    : FileImage(File(userPhoto)) as ImageProvider)
                                : null,
                            child: !hasUserPhoto
                                ? Text(
                                    hasUserName
                                        ? userName[0].toUpperCase()
                                        : (context.isArabic ? 'س' : 'S'),
                                    style: TextStyle(
                                      color: context.accentColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : AppBar(
              automaticallyImplyLeading: false,
              title: Text(
                titles[_currentIndex],
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(tr),
    );
  }

  Widget _buildExploreTab(AppLocalizations tr) {
    final isArabic = context.isArabic;

    return BlocBuilder<ApartmentCubit, ApartmentState>(
      builder: (context, state) {
        final filtered = state.filteredApartments.where((apt) {
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final matchText = apt.title.toLowerCase().contains(q) ||
                apt.city.toLowerCase().contains(q) ||
                apt.address.toLowerCase().contains(q);
            if (!matchText) return false;
          }

          if (_selectedCategory == 'luxury') {
            return apt.monthlyPrice >= 5000 || apt.area >= 120;
          } else if (_selectedCategory == 'furnished') {
            return apt.amenities.any((a) => a.contains('مطبخ') || a.contains('تكييف'));
          } else if (_selectedCategory == 'studio') {
            return apt.bedrooms <= 1;
          } else if (_selectedCategory == 'daily') {
            return apt.dailyPrice > 0;
          }
          return true;
        }).toList();

        return RefreshIndicator(
          color: context.accentColor,
          onRefresh: () async {
            context.read<ApartmentCubit>().loadApartments();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ── Search & Filter Capsule ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: context.isDark ? 0.25 : 0.04,
                          ),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Icon(
                          Icons.search_rounded,
                          color: context.accentColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchCtl,
                            onChanged: (val) => setState(() => _searchQuery = val.trim()),
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: isArabic
                                  ? 'ابحث بالمدينة، الحي، أو اسم العقار...'
                                  : 'Search city, neighborhood, or title...',
                              hintStyle: TextStyle(
                                color: context.textSecondary.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchCtl.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                        Container(
                          height: 26,
                          width: 1,
                          color: context.borderColor,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        // Filter Trigger
                        BouncingTap(
                          onTap: () => FilterBottomSheet.show(
                            context: context,
                            initialOptions: state.filterOptions,
                            onApply: (opts) =>
                                context.read<ApartmentCubit>().applyFilters(opts),
                            onReset: () =>
                                context.read<ApartmentCubit>().resetFilters(),
                            matchingCount: state.filteredApartments.length,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.tune_rounded,
                              color: state.filterOptions.hasActiveFilters
                                  ? context.accentColor
                                  : context.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Clean Category Chips ──
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildCategoryChip('all', isArabic ? 'الكل' : 'All'),
                      _buildCategoryChip('luxury', isArabic ? 'عقارات فاخرة' : 'Luxury'),
                      _buildCategoryChip('furnished', isArabic ? 'مفروشة بالكامل' : 'Furnished'),
                      _buildCategoryChip('studio', isArabic ? 'استوديوهات' : 'Studios'),
                      _buildCategoryChip('daily', isArabic ? 'إيجار يومي' : 'Daily Rent'),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),

              // ── Loading Skeletons ──
              if (state.isLoading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const ShimmerApartmentCard(),
                      childCount: 3,
                    ),
                  ),
                )
              // ── Empty State ──
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: context.accentColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.accentColor.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Icon(
                              Icons.apartment_rounded,
                              size: 40,
                              color: context.accentColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            isArabic ? 'لا توجد عقارات حالياً' : 'No properties found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isArabic
                                ? 'المنصة جاهزة لاستقبال العقارات المعتمدة الجديدة'
                                : 'The platform is ready for newly listed residences.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          BouncingTap(
                            onTap: () => context.read<ApartmentCubit>().loadApartments(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh_rounded, size: 16, color: context.accentColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    isArabic ? 'تحديث' : 'Refresh',
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              // ── Clean List of Apartment Cards ──
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final aptEntity = filtered[index];
                        final aptModel = aptEntity is ApartmentModel
                            ? aptEntity
                            : ApartmentModel.fromEntity(aptEntity);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ApartmentCard(
                            apartment: aptModel,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/apartment-detail',
                              arguments: aptModel,
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? context.accentColor : context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? context.accentColor : context.borderColor,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.black : context.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(AppLocalizations tr) {
    final wishlistCount = context.watch<WishlistCubit>().state.length;

    return LuxuryNavBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      items: [
        LuxuryNavItem(
          selectedIcon: Icons.explore_rounded,
          unselectedIcon: Icons.explore_outlined,
          label: tr.tr('explore'),
        ),
        LuxuryNavItem(
          selectedIcon: Icons.favorite_rounded,
          unselectedIcon: Icons.favorite_border_rounded,
          label: tr.tr('wishlist'),
          badgeCount: wishlistCount > 0 ? wishlistCount : null,
        ),
        LuxuryNavItem(
          selectedIcon: Icons.calendar_month_rounded,
          unselectedIcon: Icons.calendar_month_outlined,
          label: tr.tr('myBookings'),
        ),
        LuxuryNavItem(
          selectedIcon: Icons.chat_bubble_rounded,
          unselectedIcon: Icons.chat_bubble_outline_rounded,
          label: tr.tr('chats'),
        ),
        LuxuryNavItem(
          selectedIcon: Icons.person_rounded,
          unselectedIcon: Icons.person_outline_rounded,
          label: tr.tr('myAccount'),
        ),
      ],
    );
  }
}
