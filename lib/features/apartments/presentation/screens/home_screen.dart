import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/localization/app_localizations.dart';
import 'package:sakani/core/widgets/empty_state.dart';
import 'package:sakani/core/widgets/shimmer_loading.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_cubit.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_state.dart';
import 'package:sakani/features/apartments/presentation/widgets/apartment_card.dart';
import 'package:sakani/features/apartments/presentation/widgets/featured_carousel.dart';
import 'package:sakani/features/apartments/presentation/widgets/city_filter_bar.dart';
import 'package:sakani/features/apartments/presentation/widgets/filter_bottom_sheet.dart';
import 'package:sakani/features/apartments/presentation/widgets/quick_sort_bar.dart';
import 'package:sakani/features/bookings/presentation/screens/my_bookings_screen.dart';
import 'package:sakani/features/chat/presentation/screens/chat_list_screen.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';
import 'package:sakani/features/settings/presentation/screens/settings_screen.dart';

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

    final List<Widget> pages = [
      _buildExploreTab(tr),
      const MyBookingsScreen(isEmbedded: true),
      const ChatListScreen(isEmbedded: true),
      const SettingsScreen(isEmbedded: true),
    ];

    final List<String> titles = [
      tr.tr('appName'),
      tr.tr('myBookings'),
      tr.tr('chats'),
      tr.tr('settings'),
    ];

    return Scaffold(
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
        actions: _currentIndex == 0
            ? [
                IconButton(
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: context.accentColor,
                  ),
                  onPressed: () => setState(() => _currentIndex = 2),
                ),
              ]
            : null,
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _buildBottomNav(tr),
    );
  }

  Widget _buildExploreTab(AppLocalizations tr) {
    return BlocBuilder<ApartmentCubit, ApartmentState>(
      builder: (context, state) {
        final allApartments = state.apartments;
        final cities = allApartments.map((a) => a.city).toSet().toList();

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
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: AppRadius.mdBr,
                        border: Border.all(color: context.borderColor),
                        boxShadow: AppShadows.card(context),
                      ),
                      child: TextField(
                        controller: _searchCtl,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        decoration: InputDecoration(
                          hintText: 'ابحث عن مدينة، حي، أو مواصفات...',
                          hintStyle: TextStyle(
                            color: context.textSecondary.withValues(alpha: 0.6),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(Icons.search_rounded, color: context.accentColor),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 20),
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
                  GestureDetector(
                    onTap: () => FilterBottomSheet.show(
                      context: context,
                      initialOptions: state.filterOptions,
                      onApply: (opts) => context.read<ApartmentCubit>().applyFilters(opts),
                      onReset: () => context.read<ApartmentCubit>().resetFilters(),
                      matchingCount: state.filteredApartments.length,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: state.filterOptions.hasActiveFilters
                            ? context.accentColor
                            : context.cardColor,
                        borderRadius: AppRadius.mdBr,
                        border: Border.all(
                          color: state.filterOptions.hasActiveFilters
                              ? context.accentColor
                              : context.borderColor,
                        ),
                        boxShadow: AppShadows.card(context),
                      ),
                      child: Stack(
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
                              top: -6,
                              right: -6,
                              child: CircleAvatar(
                                radius: 8,
                                backgroundColor: AppColors.error,
                                child: Text(
                                  '${state.filterOptions.activeFiltersCount}',
                                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
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

            // City Filter Chips
            CityFilterBar(
              cities: cities,
              selectedCity: state.selectedCity,
              onCitySelected: (city) => context.read<ApartmentCubit>().setFilter(
                    city: city,
                    maxPrice: state.maxPrice,
                  ),
            ),
            const SizedBox(height: 8),

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
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                        Text(
                                          'جميع الشقق المتاحة',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${filtered.length} شقة',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: context.textSecondary,
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
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.borderColor, width: 0.8)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: context.accentColor,
        unselectedItemColor: context.textSecondary,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.explore_outlined),
            activeIcon: const Icon(Icons.explore_rounded),
            label: tr.tr('appName'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bookmark_border_rounded),
            activeIcon: const Icon(Icons.bookmark_rounded),
            label: tr.tr('myBookings'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: const Icon(Icons.chat_bubble_rounded),
            label: tr.tr('chats'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings_rounded),
            label: tr.tr('settings'),
          ),
        ],
      ),
    );
  }
}
