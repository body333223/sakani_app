import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/localization/app_localizations.dart';
import 'package:sakani/core/widgets/empty_state.dart';
import 'package:sakani/core/widgets/shimmer_loading.dart';
import 'package:sakani/core/widgets/notifications_bottom_sheet.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_cubit.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_state.dart';
import 'package:sakani/features/apartments/presentation/widgets/apartment_card.dart';
import 'package:sakani/features/apartments/presentation/widgets/featured_carousel.dart';
import 'package:sakani/features/apartments/presentation/widgets/filter_bottom_sheet.dart';
import 'package:sakani/features/apartments/presentation/widgets/quick_sort_bar.dart';
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
              preferredSize: const Size.fromHeight(68),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      children: [
                        // ── Profile Avatar with Photo on RIGHT ──
                        GestureDetector(
                          onTap: () => setState(() => _currentIndex = 4),
                          child: Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [context.accentColor, AppColors.goldDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: context.accentColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 20,
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
                                          : 'س',
                                      style: TextStyle(
                                        color: context.accentColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // ── Greeting & Welcome ──
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'مرحباً، ${hasUserName ? userName.split(' ').first : "بك"}',
                                      style: TextStyle(
                                        color: context.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text('👋', style: TextStyle(fontSize: 14)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ابحث عن شقتك المثالية',
                                style: TextStyle(
                                  color: context.textSecondary.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ── Notifications on LEFT ──
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: context.borderColor,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: context.isDark ? 0.2 : 0.04,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.notifications_outlined,
                                  color: context.accentColor,
                                  size: 22,
                                ),
                                onPressed: () => NotificationsBottomSheet.show(context),
                                tooltip: 'الإشعارات',
                              ),
                            ),
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: context.surfaceColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
    return BlocBuilder<ApartmentCubit, ApartmentState>(
      builder: (context, state) {
        final allApartments = state.apartments;
        final filtered = state.filteredApartments.where((apt) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return apt.title.toLowerCase().contains(q) ||
              apt.city.toLowerCase().contains(q) ||
              apt.address.toLowerCase().contains(q);
        }).toList();

        return Column(
          children: [
            // Search Input Row with Filter Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : context.borderColor,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchCtl,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن مدينة، حي، أو مواصفات...',
                          hintStyle: TextStyle(
                            color: context.textSecondary.withValues(alpha: 0.65),
                            fontSize: 13.5,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: context.accentColor,
                            size: 22,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchCtl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter Button with Badge
                  BouncingTap(
                    scaleFactor: 0.93,
                    onTap: () => FilterBottomSheet.show(
                      context: context,
                      initialOptions: state.filterOptions,
                      onApply: (opts) => context.read<ApartmentCubit>().applyFilters(opts),
                      onReset: () => context.read<ApartmentCubit>().resetFilters(),
                      matchingCount: state.filteredApartments.length,
                    ),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: state.filterOptions.hasActiveFilters
                            ? LinearGradient(
                                colors: [context.accentColor, AppColors.goldDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: state.filterOptions.hasActiveFilters ? null : context.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: state.filterOptions.hasActiveFilters
                              ? context.accentColor
                              : (context.isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : context.borderColor),
                          width: 1.2,
                        ),
                        boxShadow: state.filterOptions.hasActiveFilters
                            ? [
                                BoxShadow(
                                  color: context.accentColor.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: state.filterOptions.hasActiveFilters
                                ? Colors.black
                                : context.accentColor,
                            size: 22,
                          ),
                          if (state.filterOptions.hasActiveFilters)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                child: Center(
                                  child: Text(
                                    '${state.filterOptions.activeFiltersCount}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Quick Sorting Pills
            QuickSortBar(
              selectedSort: state.filterOptions.sortBy,
              onSortChanged: (sort) => context.read<ApartmentCubit>().setSortBy(sort),
            ),
            const SizedBox(height: 8),

            // Apartment List or Skeletons
            Expanded(
              child: state.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 4,
                      itemBuilder: (_, _) => const ShimmerApartmentCard(),
                    )
                  : RefreshIndicator(
                      color: context.accentColor,
                      onRefresh: () async {
                        context.read<ApartmentCubit>().loadApartments(
                              city: state.selectedCity,
                              maxPrice: state.maxPrice,
                            );
                      },
                      child: filtered.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 60),
                                EmptyState(
                                  icon: Icons.holiday_village_outlined,
                                  title: tr.tr('noApartments'),
                                  subtitle: _searchQuery.isNotEmpty
                                      ? 'جرب البحث بكلمات مختلفة أو تعديل خيارات الفلتر'
                                      : 'لا توجد شقق مطابقة للبحث أو الفلتر المحدد',
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 96),
                              itemCount: filtered.length + (_searchQuery.isEmpty && allApartments.length > 1 ? 2 : 0),
                              itemBuilder: (context, index) {
                                final showFeatured = _searchQuery.isEmpty && allApartments.length > 1;

                                if (showFeatured && index == 0) {
                                  final featuredList = allApartments.map((e) => e is ApartmentModel ? e : ApartmentModel.fromEntity(e)).toList();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: FeaturedCarousel(apartments: featuredList),
                                  );
                                }

                                if (showFeatured && index == 1) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: context.accentColor,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'جميع الشقق المتاحة',
                                              style: TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                                color: context.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: context.accentColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${filtered.length} شقة',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: context.accentColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final actualIndex = showFeatured ? index - 2 : index;
                                final aptEntity = filtered[actualIndex];
                                final aptModel = aptEntity is ApartmentModel
                                    ? aptEntity
                                    : ApartmentModel.fromEntity(aptEntity);
                                return ApartmentCard(
                                  apartment: aptModel,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/apartment-detail',
                                    arguments: aptModel,
                                  ),
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
