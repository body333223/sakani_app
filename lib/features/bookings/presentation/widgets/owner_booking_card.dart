import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/glass_card.dart';
import 'package:sakani/features/bookings/data/models/booking_model.dart';
import 'package:sakani/features/bookings/presentation/widgets/booking_status_chip.dart';
import 'package:sakani/features/contracts/data/services/contract_service.dart';
import 'package:sakani/features/contracts/presentation/screens/digital_contract_screen.dart';
import 'package:sakani/features/reviews/presentation/widgets/trust_badge_widget.dart';
import 'package:sakani/features/reviews/presentation/widgets/review_modal.dart';

class OwnerBookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onCancel;
  final VoidCallback? onAccept;
  final VoidCallback? onRefresh;

  const OwnerBookingCard({
    super.key,
    required this.booking,
    this.onCancel,
    this.onAccept,
    this.onRefresh,
  });

  String _formatDate(DateTime dt) => '${dt.day}/${dt.month}/${dt.year}';

  Future<void> _openContract(BuildContext context) async {
    final contract = await ContractService().generateOrGetContract(
      booking: booking,
    );
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DigitalContractScreen(contract: contract),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: StyledCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.apartmentTitle,
                    style: GoogleFonts.tajawal(
                      color: context.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
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
                  color: AppColors.gold,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  booking.tenantName,
                  style: GoogleFonts.tajawal(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                TrustBadgeWidget(
                  userId: booking.tenantId,
                  isOwner: false,
                  isCompact: true,
                ),
                const Spacer(),
                Icon(
                  Icons.people_rounded,
                  color: AppColors.gold,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${booking.guests} نزلاء',
                  style: GoogleFonts.tajawal(color: context.textSecondary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.gold,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}',
                  style: GoogleFonts.tajawal(color: context.textSecondary, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '${booking.totalAmount.round()} ج.م',
                  style: GoogleFonts.tajawal(
                    color: AppColors.gold,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),

            // ── If Pending: Accept / Reject actions ──
            if (booking.status == 'قيد الانتظار') ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: context.borderColor),
              ),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text('قبول وتوثيق العقد', style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: const Color(0xFF080C14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: Text('رفض الطلب', style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // ── If Accepted: View Certified Contract & Mutual Review actions ──
            if (booking.status == 'مقبول') ...[
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
                        onPressed: () => _openContract(context),
                        icon: const Icon(Icons.description_rounded, size: 16),
                        label: Text('عرض العقد الموثق 📄', style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                          foregroundColor: AppColors.gold,
                          side: const BorderSide(color: AppColors.gold, width: 1.2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ReviewModals.showOwnerReviewModal(
                            context,
                            booking: booking,
                            onSubmitted: () {
                              if (onRefresh != null) onRefresh!();
                            },
                          );
                        },
                        icon: const Icon(Icons.star_rounded, size: 16),
                        label: Text('تقييم المستأجر ⭐', style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success.withValues(alpha: 0.15),
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success, width: 1.2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
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
