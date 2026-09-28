import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';

class QuickSortBar extends StatelessWidget {
  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  const QuickSortBar({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  static const List<Map<String, String>> _sortOptions = [
    {'key': 'newest', 'label': 'الأحدث', 'icon': '⭐'},
    {'key': 'price_asc', 'label': 'الأقل سعراً', 'icon': '📉'},
    {'key': 'price_desc', 'label': 'الأعلى سعراً', 'icon': '📈'},
    {'key': 'area_desc', 'label': 'الأكبر مساحة', 'icon': '📐'},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _sortOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final opt = _sortOptions[index];
          final isSelected = selectedSort == opt['key'];

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSortChanged(opt['key']!),
              borderRadius: AppRadius.pillBr,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.accentColor
                      : context.cardColor,
                  borderRadius: AppRadius.pillBr,
                  border: Border.all(
                    color: isSelected
                        ? context.accentColor
                        : context.borderColor,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: context.accentColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      opt['icon']!,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      opt['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? Colors.black
                            : context.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
