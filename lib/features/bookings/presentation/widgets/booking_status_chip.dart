import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';

class BookingStatusChip extends StatelessWidget {
  final String status;
  const BookingStatusChip({super.key, required this.status});

  (Color, IconData) _statusStyle() {
    switch (status) {
      case 'قيد الانتظار':
        return (AppColors.warning, Icons.schedule_rounded);
      case 'مقبول':
        return (AppColors.success, Icons.check_circle_rounded);
      case 'نشط':
        return (AppColors.gold, Icons.play_circle_rounded);
      case 'ملغي':
      case 'مرفوض':
        return (AppColors.error, Icons.cancel_rounded);
      case 'مكتمل':
      case 'منتهي':
        return (Colors.grey, Icons.task_alt_rounded);
      default:
        return (Colors.grey, Icons.circle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _statusStyle();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillBr,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
