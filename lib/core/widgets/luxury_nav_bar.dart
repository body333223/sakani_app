import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';

class LuxuryNavItem {
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final String label;
  final int? badgeCount;

  const LuxuryNavItem({
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.label,
    this.badgeCount,
  });
}

class LuxuryNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LuxuryNavItem> items;

  const LuxuryNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: context.isDark
                ? const Color(0xFF0F172A).withValues(alpha: 0.88)
                : Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(
              color: context.isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDark ? 0.45 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              if (context.isDark)
                BoxShadow(
                  color: context.accentColor.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -2),
                ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isSelected = currentIndex == index;

                return GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 14 : 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.accentColor.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedScale(
                              scale: isSelected ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                isSelected ? item.selectedIcon : item.unselectedIcon,
                                color: isSelected
                                    ? context.accentColor
                                    : context.textSecondary,
                                size: 23,
                              ),
                            ),
                            if (item.badgeCount != null && item.badgeCount! > 0)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${item.badgeCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          AnimatedOpacity(
                            opacity: isSelected ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: context.accentColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
