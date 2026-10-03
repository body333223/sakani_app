import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/bookings/data/models/booking_model.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakani/features/bookings/presentation/providers/booking_provider.dart';
import 'package:sakani/features/bookings/presentation/widgets/booking_status_chip.dart';
import 'package:sakani/core/widgets/empty_state.dart';
import 'package:sakani/core/widgets/glass_card.dart';
import 'package:sakani/core/widgets/loading_widget.dart';
import 'package:sakani/features/contracts/data/services/contract_service.dart';
import 'package:sakani/features/contracts/presentation/screens/digital_contract_screen.dart';
import 'package:sakani/features/reviews/presentation/widgets/trust_badge_widget.dart';
import 'package:sakani/features/reviews/presentation/widgets/review_modal.dart';

class MyBookingsScreen extends StatefulWidget {
  final bool isEmbedded;
  const MyBookingsScreen({super.key, this.isEmbedded = false});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null && mounted) {
        context.read<BookingProvider>().getTenantBookings(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = Consumer<BookingProvider>(
      builder: (context, prov, _) {
        if (prov.isLoading) {
          return const LoadingWidget();
        }
        final bookings = prov.tenantBookings;
        if (bookings.isEmpty) {
          return const EmptyState(
            icon: Icons.event_busy_rounded,
            title: 'لا توجد حجوزات حتى الآن',
            subtitle: 'ستظهر جميع حجوزاتك وعقودك الإلكترونية الموثقة هنا فور طلب حجز شقة.',
          );
        }
        return RefreshIndicator(
          color: AppColors.gold,
          onRefresh: () async {
            final user = context.read<AuthProvider>().user;
            if (user != null) {
              await context.read<BookingProvider>().getTenantBookings(user.uid);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _TenantBookingCard(
                booking: bookings[index],
                onRefresh: () {
                  final user = context.read<AuthProvider>().user;
                  if (user != null) {
                    context.read<BookingProvider>().getTenantBookings(user.uid);
                  }
                },
              );
            },
          ),
        );
      },
    );

    if (widget.isEmbedded) {
      return bodyContent;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'حجوزاتي وعقودي الموثقة',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.bold, fontSize: 17),
        ),
      ),
      body: bodyContent,
    );
  }
}

class _TenantBookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onRefresh;

  const _TenantBookingCard({
    required this.booking,
    required this.onRefresh,
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
                const Icon(Icons.home_work_rounded, color: AppColors.gold, size: 16),
                const SizedBox(width: 6),
                Text(
                  'المالك المعتمد',
                  style: GoogleFonts.tajawal(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                TrustBadgeWidget(
                  userId: booking.ownerId,
                  isOwner: true,
                  isCompact: true,
                ),
                const Spacer(),
                const Icon(Icons.people_rounded, color: AppColors.gold, size: 16),
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
                const Icon(Icons.calendar_month_rounded, color: AppColors.gold, size: 16),
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

            // ── Contract & Review Action Buttons if Accepted ──
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
                        label: Text(
                          'عقد الإيجار الموثق 📄',
                          style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
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
                          ReviewModals.showTenantReviewModal(
                            context,
                            booking: booking,
                            onSubmitted: onRefresh,
                          );
                        },
                        icon: const Icon(Icons.star_rounded, size: 16),
                        label: Text(
                          'تقييم التجربة ⭐',
                          style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
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
