import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/bookings/data/models/booking_model.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakani/features/bookings/presentation/providers/booking_provider.dart';
import 'package:sakani/core/widgets/glass_card.dart';
import 'package:sakani/core/widgets/gradient_button.dart';
import 'package:sakani/core/widgets/section_header.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';
import 'package:sakani/features/bookings/presentation/cubit/booking_cubit.dart';
import 'package:sakani/core/services/kyc_service.dart';
import 'package:sakani/features/auth/presentation/screens/kyc_screen.dart';

class BookingScreen extends StatefulWidget {
  final Apartment apartment;
  const BookingScreen({super.key, required this.apartment});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 31));
  String _periodType = 'شهري';
  int _guests = 1;

  @override
  void initState() {
    super.initState();
    _periodType = widget.apartment.availableRentTypes.isNotEmpty
        ? widget.apartment.availableRentTypes.first
        : 'شهري';
    if (_periodType == 'يومي') {
      _endDate = _startDate.add(const Duration(days: 1));
    } else if (_periodType == 'سنوي') {
      _endDate = _startDate.add(const Duration(days: 365));
    } else {
      _endDate = _startDate.add(const Duration(days: 30));
    }
  }

  double get _totalAmount {
    switch (_periodType) {
      case 'يومي':
        return widget.apartment.dailyPrice *
            (_endDate.difference(_startDate).inDays);
      case 'شهري':
        return widget.apartment.monthlyPrice;
      case 'سنوي':
        return widget.apartment.yearlyPrice;
      default:
        return widget.apartment.monthlyPrice;
    }
  }

  double get _commission => _totalAmount * 0.1;
  double get _totalWithCommission =>
      _totalAmount + _commission + widget.apartment.securityDeposit;

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: isStart
          ? now.add(const Duration(days: 1))
          : _startDate.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: context.isDark
                ? ColorScheme.dark(
                    primary: context.accentColor,
                    onPrimary: Colors.black,
                    surface: AppColors.darkSurface,
                  )
                : ColorScheme.light(
                    primary: context.accentColor,
                    onPrimary: Colors.white,
                    surface: AppColors.lightSurface,
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _book() async {
    if (!_formKey.currentState!.validate()) return;

    if (!KycService().isVerified) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBr),
          title: Row(
            children: [
              Icon(Icons.shield_outlined, color: context.accentColor),
              const SizedBox(width: 8),
              const Text('توثيق الهوية الرسمية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            ],
          ),
          content: const Text(
            'وفقاً للتعليمات الأمنية، يُشترط رفع صورة بطاقة الرقم القومي أو جواز السفر لضمان حقوق المؤجر والمستأجر. هل ترغب في رفع الهوية الآن؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('المتابعة وتأكيد الحجز', style: TextStyle(color: context.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx, false);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KycScreen()),
                );
                setState(() {});
              },
              child: const Text('رفع الهوية الآن'),
            ),
          ],
        ),
      );
      if (proceed != true && !KycService().isVerified) return;
    }

    if (!mounted) return;

    final bookingProv = context.read<BookingProvider>();
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final booking = Booking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      apartmentId: widget.apartment.id,
      ownerId: widget.apartment.ownerId,
      tenantId: user.uid,
      tenantName: user.name,
      apartmentTitle: widget.apartment.title,
      startDate: _startDate,
      endDate: _endDate,
      periodType: _periodType,
      totalAmount: _totalAmount,
      commissionAmount: _commission,
      securityDeposit: widget.apartment.securityDeposit,
      guests: _guests,
      status: 'قيد الانتظار',
    );
    final success = await bookingProv.createBooking(booking);
    if (!mounted) return;
    if (success) {
      try {
        context.read<BookingCubit>().loadTenantBookings(user.uid);
      } catch (_) {}
      AppSnackbar.show(
        context,
        message: 'تم إرسال طلب الحجز بنجاح',
        type: ToastType.success,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حجز الشقة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Apartment Summary ──
              StyledCard(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.smBr,
                      child: widget.apartment.images.isNotEmpty
                          ? Image.network(
                              widget.apartment.images[0],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _AptPlaceholder(),
                            )
                          : _AptPlaceholder(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.apartment.title,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: context.accentColor,
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                widget.apartment.city,
                                style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Rental Type ──
              const SectionHeader(title: 'نوع الإيجار'),
              Row(
                children: widget.apartment.availableRentTypes.map((type) {
                  final selected = _periodType == type;
                  final index = widget.apartment.availableRentTypes.indexOf(type);
                  final isFirst = index == 0;
                  final isLast = index == widget.apartment.availableRentTypes.length - 1;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: !isLast ? 6 : 0,
                        right: !isFirst ? 6 : 0,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() {
                            _periodType = type;
                            if (type == 'يومي') {
                              _endDate = _startDate.add(const Duration(days: 1));
                            } else if (type == 'شهري') {
                              _endDate = _startDate.add(const Duration(days: 30));
                            } else if (type == 'سنوي') {
                              _endDate = _startDate.add(const Duration(days: 365));
                            }
                          }),
                          borderRadius: AppRadius.mdBr,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: selected ? AppGradients.gold : null,
                              color: selected ? null : context.cardColor,
                              borderRadius: AppRadius.mdBr,
                              border: Border.all(
                                color: selected
                                    ? Colors.transparent
                                    : context.borderColor,
                              ),
                              boxShadow: selected ? AppShadows.goldGlow : null,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  type,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.black
                                        : context.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${type == 'يومي'
                                      ? widget.apartment.dailyPrice
                                      : type == 'شهري'
                                      ? widget.apartment.monthlyPrice
                                      : widget.apartment.yearlyPrice} جنية',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.black.withValues(alpha: 0.7)
                                        : context.accentColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // ── Dates ──
              const SectionHeader(title: 'تاريخ الحجز'),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'من',
                      date: _startDate,
                      onTap: () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'إلى',
                      date: _endDate,
                      onTap: () => _pickDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Guests ──
              const SectionHeader(title: 'عدد الضيوف'),
              Row(
                children: [
                  _GuestButton(
                    icon: Icons.remove_rounded,
                    onTap: () {
                      if (_guests > 1) setState(() => _guests--);
                    },
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '$_guests',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 20),
                  _GuestButton(
                    icon: Icons.add_rounded,
                    onTap: () {
                      if (_guests < widget.apartment.maxGuests) {
                        setState(() => _guests++);
                      }
                    },
                  ),
                ],
              ),
              // ── Identity Verification (KYC) Card ──
              Builder(
                builder: (context) {
                  final isVerified = KycService().isVerified;
                  final kycData = KycService().currentData;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isVerified
                          ? AppColors.success.withValues(alpha: 0.1)
                          : context.accentColor.withValues(alpha: 0.1),
                      borderRadius: AppRadius.mdBr,
                      border: Border.all(
                        color: isVerified
                            ? AppColors.success.withValues(alpha: 0.3)
                            : context.accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isVerified ? Icons.verified_user_rounded : Icons.badge_outlined,
                          color: isVerified ? AppColors.success : context.accentColor,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isVerified ? 'الهوية موثقة رسمياً ✅' : 'توثيق الهوية لتأكيد الحجز',
                                style: TextStyle(
                                  color: isVerified ? AppColors.success : context.accentColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isVerified
                                    ? 'بياناتك معتمدة (${kycData.documentType == "national_id" ? "بطاقة الرقم القومي" : "جواز السفر"})'
                                    : 'ارفع صورة البطاقة أو الباسبور لحماية وتأمين حجزك',
                                style: TextStyle(color: context.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const KycScreen()),
                            );
                            setState(() {});
                          },
                          child: Text(
                            isVerified ? 'تعديل' : 'رفع البطاقة',
                            style: TextStyle(
                              color: isVerified ? AppColors.success : context.accentColor,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // ── Summary ──
              StyledCard(
                child: Column(
                  children: [
                    _SummaryRow(label: 'المبلغ', amount: _totalAmount),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'عمولة التطبيق (10%)',
                      amount: _commission,
                    ),
                    _SummaryRow(
                      label: 'التأمين (لمحفظة التطبيق)',
                      amount: widget.apartment.securityDeposit,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        color: context.accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    _SummaryRow(
                      label: 'الإجمالي المطلوب دفعه',
                      amount: _totalWithCommission,
                      isTotal: true,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.accentColor.withValues(alpha: 0.1),
                        borderRadius: AppRadius.smBr,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: context.accentColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'يتم حفظ التأمين في محفظة التطبيق لضمان حقوق الطرفين، ولا يذهب للمالك مباشرة. وهو قابل للاسترداد.',
                              style: TextStyle(
                                color: context.accentColor,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(top: BorderSide(color: context.borderColor)),
        ),
        child: Consumer<BookingProvider>(
          builder: (context, prov, _) => GradientButton(
            text: 'تأكيد الحجز',
            isLoading: prov.isLoading,
            onPressed: prov.isLoading ? null : _book,
            icon: Icons.check_circle_rounded,
          ),
        ),
      ),
    );
  }
}

class _AptPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: AppRadius.smBr,
      ),
      child: Icon(
        Icons.home_work_outlined,
        color: context.accentColor.withValues(alpha: 0.4),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdBr,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: AppRadius.mdBr,
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: context.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GuestButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdBr,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            border: Border.all(color: context.accentColor),
            borderRadius: AppRadius.mdBr,
          ),
          child: Icon(icon, color: context.accentColor, size: 22),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isTotal;

  const _SummaryRow({
    required this.label,
    required this.amount,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? context.accentColor : context.textSecondary,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        Text(
          '${amount.round()} جنية',
          style: TextStyle(
            color: isTotal ? context.accentColor : context.textPrimary,
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
