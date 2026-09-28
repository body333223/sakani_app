import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/bookings/data/models/booking_model.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakani/features/bookings/presentation/providers/booking_provider.dart';
import 'package:sakani/features/bookings/presentation/widgets/booking_status_chip.dart';
import 'package:sakani/core/widgets/empty_state.dart';
import 'package:sakani/core/widgets/glass_card.dart';
import 'package:sakani/core/widgets/loading_widget.dart';

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
            title: 'لا توجد حجوزات',
            subtitle: 'ستظهر حجوزاتك هنا بعد حجز شقة',
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            final user = context.read<AuthProvider>().user;
            if (user != null) {
              await context.read<BookingProvider>().getTenantBookings(user.uid);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return _BookingCard(booking: bookings[index]);
            },
          ),
        );
      },
    );

    if (widget.isEmbedded) {
      return bodyContent;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('حجوزاتي')),
      body: bodyContent,
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                BookingStatusChip(status: booking.status),
              ],
            ),
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.person_outline_rounded,
              text: 'المالك: ${booking.ownerId}',
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.calendar_month_rounded,
              text:
                  '${_formatDate(booking.startDate)} - ${_formatDate(booking.endDate)}',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _InfoRow(
                  icon: Icons.people_rounded,
                  text: '${booking.guests} ضيوف',
                ),
                const Spacer(),
                Text(
                  '${booking.totalAmount.round()} جنية',
                  style: TextStyle(
                    color: context.accentColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: context.accentColor, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
