import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';

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

  @override
  Widget build(BuildContext context) {
    if (cities.isEmpty) return const SizedBox.shrink();

    final allItems = ['', ...cities];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allItems.length,
        itemBuilder: (context, index) {
          final city = allItems[index];
          final isAll = city.isEmpty;
          final label = isAll ? 'الكل' : city;
          final isSelected = isAll ? (selectedCity == null || selectedCity!.isEmpty) : selectedCity == city;

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: context.accentColor.withValues(alpha: 0.18),
              checkmarkColor: context.accentColor,
              backgroundColor: context.cardColor,
              labelStyle: TextStyle(
                color: isSelected ? context.accentColor : context.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.pillBr,
                side: BorderSide(
                  color: isSelected
                      ? context.accentColor.withValues(alpha: 0.4)
                      : context.borderColor,
                ),
              ),
              onSelected: (_) => onCitySelected(isAll ? null : city),
            ),
          );
        },
      ),
    );
  }
}
