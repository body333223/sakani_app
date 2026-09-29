import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/staggered_entrance.dart';

class QuickSortOption {
  final String key;
  final String label;
  final IconData icon;

  const QuickSortOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class QuickSortBar extends StatelessWidget {
  final String selectedSort;
  final ValueChanged<String> onSortChanged;

  const QuickSortBar({
    super.key,
    required this.selectedSort,
    required this.onSortChanged,
  });

  static const List<QuickSortOption> _sortOptions = [
    QuickSortOption(
      key: 'newest',
      label: 'الأحدث',
      icon: Icons.auto_awesome_rounded,
    ),
    QuickSortOption(
      key: 'price_asc',
      label: 'الأقل سعراً',
      icon: Icons.trending_down_rounded,
    ),
    QuickSortOption(
      key: 'price_desc',
      label: 'الأعلى سعراً',
      icon: Icons.trending_up_rounded,
    ),
    QuickSortOption(
      key: 'area_desc',
      label: 'الأكبر مساحة',
      icon: Icons.straighten_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _sortOptions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final opt = _sortOptions[index];
          final isSelected = selectedSort == opt.key;

          return BouncingTap(
            scaleFactor: 0.95,
            onTap: () => onSortChanged(opt.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.accentColor.withValues(alpha: 0.16)
                    : context.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? context.accentColor
                      : (context.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : context.borderColor),
                  width: isSelected ? 1.4 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: context.accentColor.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    opt.icon,
                    size: 15,
                    color: isSelected ? context.accentColor : context.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? context.accentColor : context.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
