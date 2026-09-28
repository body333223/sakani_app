import 'package:flutter/material.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/glass_card.dart';
import 'package:sakani/features/bookings/data/models/booking_model.dart';
import 'package:sakani/features/bookings/presentation/widgets/booking_status_chip.dart';

class OwnerBookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onCancel;
  final VoidCallback? onAccept;

  const OwnerBookingCard({
    super.key,
    required this.booking,
    this.onCancel,
    this.onAccept,
  });

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: StyledCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.apartmentTitle,
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                BookingStatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  color: context.accentColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  booking.tenantName,
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
                const Spacer(),
                Icon(
                  Icons.people_rounded,
                  color: context.accentColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${booking.guests} نزلاء',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: context.accentColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '${booking.totalAmount.round()} ج.م',
                  style: TextStyle(
                    color: context.accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (booking.status == 'قيد الانتظار') ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: context.borderColor),
              ),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('قبول الحجز'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('رفض الطلب'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
