import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';

class CustomBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final bool isFilled;

  const CustomBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
    this.isFilled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isFilled ? color : color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillBr,
        border: Border.all(
          color: isFilled ? Colors.transparent : color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: isFilled ? Colors.white : color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isFilled ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }
}
