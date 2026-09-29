import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/staggered_entrance.dart';

class CityFilterBar extends StatelessWidget {
  final List<String> cities;
  final String? selectedCity;
  final ValueChanged<String?> onCitySelected;

  const CityFilterBar({
    super.key,
    required this.cities,
    required this.selectedCity,
    required this.onCitySelected,
  });

  IconData _getCityIcon(String city) {
    if (city.isEmpty || city == 'الكل') return Icons.explore_rounded;
    if (city.contains('قاهرة')) return Icons.location_city_rounded;
    if (city.contains('إسكندرية') || city.contains('اسكندرية')) return Icons.waves_rounded;
    if (city.contains('جيزة')) return Icons.account_balance_rounded;
    if (city.contains('زايد')) return Icons.villa_rounded;
    if (city.contains('أكتوبر') || city.contains('اكتوبر')) return Icons.apartment_rounded;
    if (city.contains('تجمع')) return Icons.domain_rounded;
    if (city.contains('شرم') || city.contains('غردقة')) return Icons.beach_access_rounded;
    return Icons.place_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (cities.isEmpty) return const SizedBox.shrink();

    final allItems = ['', ...cities];

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allItems.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final city = allItems[index];
          final isAll = city.isEmpty;
          final label = isAll ? 'الكل' : city;
          final isSelected = isAll
              ? (selectedCity == null || selectedCity!.isEmpty)
              : selectedCity == city;
          final icon = _getCityIcon(label);

          return BouncingTap(
            scaleFactor: 0.94,
            onTap: () => onCitySelected(isAll ? null : city),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          context.accentColor,
                          AppColors.goldDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : context.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? context.accentColor
                      : (context.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : context.borderColor),
                  width: isSelected ? 1.5 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: context.accentColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.black.withValues(alpha: 0.15)
                          : context.accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 15,
                      color: isSelected ? Colors.black : context.accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.black : context.textPrimary,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
