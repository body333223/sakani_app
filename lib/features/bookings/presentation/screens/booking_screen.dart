import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/apartments/data/models/apartment_model.dart';
import 'package:sakani/features/bookings/data/models/booking_model.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakani/features/bookings/presentation/providers/booking_provider.dart';
import 'package:sakani/core/widgets/gradient_button.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';
import 'package:sakani/core/services/platform_config_service.dart';
import 'package:sakani/core/services/fair_deposit_service.dart';
import 'package:sakani/core/security/security_sanitizer.dart';
import 'package:sakani/core/localization/app_localizations.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';
import 'package:sakani/core/security/booking_security_guard.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/core/services/push_notification_service.dart';

/// شاشة تأكيد الحجز الحديثة فائقة السرعة ومريحة للعين (Clean & Eye-Friendly UI)
class BookingScreen extends StatefulWidget {
  final Apartment apartment;
  const BookingScreen({super.key, required this.apartment});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 31));
  String _periodType = 'شهري';
  int _guests = 1;
  String _paymentMethod = 'cash_on_arrival'; // 'cash_on_arrival', 'card', 'instapay'
  bool _isSubmitting = false;

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

  int get _daysCount {
    final diff = _endDate.difference(_startDate).inDays;
    return diff > 0 ? diff : 1;
  }

  double get _totalAmount {
    switch (_periodType) {
      case 'يومي':
        return widget.apartment.dailyPrice * _daysCount;
      case 'شهري':
        if (_daysCount <= 30) {
          return widget.apartment.monthlyPrice;
        }
        final fullMonths = _daysCount ~/ 30;
        final remainingDays = _daysCount % 30;
        return (fullMonths * widget.apartment.monthlyPrice) +
            (remainingDays * (widget.apartment.monthlyPrice / 30.0));
      case 'سنوي':
        if (_daysCount <= 365) {
          return widget.apartment.yearlyPrice;
        }
        return (_daysCount / 365.0) * widget.apartment.yearlyPrice;
      default:
        return widget.apartment.monthlyPrice;
    }
  }

  double get _commissionRate => PlatformConfigService().commissionRate;
  double get _commission => PlatformConfigService().calculateCommission(_totalAmount);

  double get _fairDeposit => FairDepositService.calculateFairDeposit(
        city: widget.apartment.city,
        periodType: _periodType,
        basePrice: _periodType == 'يومي'
            ? widget.apartment.dailyPrice
            : (_periodType == 'سنوي'
                ? widget.apartment.yearlyPrice
                : widget.apartment.monthlyPrice),
        daysCount: _daysCount,
        apartmentSpecifiedDeposit: widget.apartment.securityDeposit,
      );

  double get _totalWithCommission => _totalAmount + _commission + _fairDeposit;

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: isStart ? now.add(const Duration(days: 1)) : _startDate.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: context.isDark
                ? ColorScheme.dark(
                    primary: context.accentColor,
                    surface: AppColors.darkSurface,
                    onPrimary: Colors.black,
                  )
                : ColorScheme.light(
                    primary: context.accentColor,
                    surface: AppColors.lightSurface,
                    onPrimary: Colors.white,
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

  Future<void> _confirmBooking() async {
    final eligibility = BookingSecurityGuard.checkEligibility(
      context: context,
      apartmentOwnerId: widget.apartment.ownerId,
    );
    if (!eligibility.isEligible) {
      AppSnackbar.show(
        context,
        message: eligibility.message ?? 'لا يمكن إتمام الحجز من هذا الحساب.',
        type: ToastType.error,
      );
      BookingSecurityGuard.showBlockedModal(
        context,
        eligibility: eligibility,
        apartmentTitle: widget.apartment.title,
      );
      return;
    }

    final user = context.read<AuthProvider>().user;
    if (user == null) {
      AppSnackbar.show(context, message: 'يرجى تسجيل الدخول أولاً للمتابعة', type: ToastType.error);
      return;
    }

    // Security Guard: Anti-tampering check
    if (_totalAmount <= 0 || _daysCount <= 0 || _commission < 0 || _fairDeposit < 0) {
      AppSnackbar.show(context, message: 'بيانات الحجز أو التكلفة غير صالحة', type: ToastType.error);
      return;
    }

    setState(() => _isSubmitting = true);

    final booking = Booking(
      id: 'book_${DateTime.now().millisecondsSinceEpoch}',
      apartmentId: widget.apartment.id,
      ownerId: widget.apartment.ownerId,
      tenantId: user.uid,
      tenantName: SecuritySanitizer.sanitizeSql(user.name.isNotEmpty ? user.name : 'مستأجر سكني'),
      apartmentTitle: widget.apartment.title,
      startDate: _startDate,
      endDate: _endDate,
      periodType: _periodType,
      totalAmount: _totalAmount,
      commissionAmount: _commission,
      securityDeposit: _fairDeposit,
      guests: _guests,
      status: 'قيد الانتظار',
    );

    final bookingProv = context.read<BookingProvider>();
    final success = await bookingProv.createBooking(booking);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      // Trigger instant push notification with sound to the owner
      await PushNotificationService().notifyOwnerNewBooking(
        context: context,
        ownerId: widget.apartment.ownerId,
        tenantName: booking.tenantName,
        apartmentTitle: widget.apartment.title,
        totalAmount: _totalAmount,
        bookingId: booking.id,
      );

      if (!mounted) return;

      // Show quick success bottom sheet
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        builder: (ctx) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.success, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'تم إرسال طلب الحجز بنجاح!',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'تم إرسال طلبك إلى المالك مباشرة للموافقة. ستصلك رسالة وإشعار فور تأكيد الحجز.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.accentColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('حسناً، تم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      AppSnackbar.show(
        context,
        message: 'حدث خطأ أثناء إرسال الحجز، يرجى المحاولة مرة أخرى',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final eligibility = BookingSecurityGuard.checkEligibility(
      context: context,
      apartmentOwnerId: widget.apartment.ownerId,
    );

    if (eligibility.isMerchantRestricted || eligibility.isOwnProperty) {
      return _buildBlockedScreen(context, eligibility);
    }

    final lang = context.watch<LocaleProvider>().lang;
    final tr = AppLocalizations(lang);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text(
          tr.tr('bookingTitle'),
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Apartment Card at a Glance ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: widget.apartment.images.isNotEmpty
                        ? Image.network(
                            widget.apartment.images[0],
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.apartment.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 14, color: context.accentColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.apartment.city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: context.textSecondary, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.apartment.monthlyPrice.round()} ج.م / شهر',
                          style: TextStyle(
                            color: context.accentColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── 2. Rental Type Selector ──
            Text(
              'نوع الإيجار',
              style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: widget.apartment.availableRentTypes.map((type) {
                final isSelected = _periodType == type;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _periodType = type;
                          if (type == 'يومي') {
                            _endDate = _startDate.add(const Duration(days: 1));
                          } else if (type == 'سنوي') {
                            _endDate = _startDate.add(const Duration(days: 365));
                          } else {
                            _endDate = _startDate.add(const Duration(days: 30));
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? context.accentColor : context.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? context.accentColor : context.borderColor,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            type,
                            style: TextStyle(
                              color: isSelected ? Colors.black : context.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // ── 3. Date Range Selection ──
            Text(
              'فترة الإقامة',
              style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateBox(
                    title: 'تاريخ الوصول',
                    date: _startDate,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateBox(
                    title: 'تاريخ المغادرة',
                    date: _endDate,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 15, color: context.accentColor),
                  const SizedBox(width: 8),
                  Text(
                    'المدة الإجمالية: $_daysCount يوم',
                    style: TextStyle(
                      color: context.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── 4. Guests Counter ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.people_outline_rounded, color: context.accentColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'عدد النزلاء',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: _guests > 1 ? context.accentColor : context.textSecondary.withValues(alpha: 0.3),
                    onPressed: _guests > 1 ? () => setState(() => _guests--) : null,
                  ),
                  Text(
                    '$_guests',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: _guests < widget.apartment.maxGuests
                        ? context.accentColor
                        : context.textSecondary.withValues(alpha: 0.3),
                    onPressed: _guests < widget.apartment.maxGuests ? () => setState(() => _guests++) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── 5. Payment Preference (NO WALLET REQUIREMENT) ──
            Text(
              'طريقة الدفع والتأكيد',
              style: TextStyle(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _PaymentCard(
              title: 'الدفع عند المعاينة والاستلام',
              subtitle: 'ادفع مباشرة للمالك عند فحص الشقة واستلام المفاتيح',
              icon: Icons.handshake_outlined,
              isSelected: _paymentMethod == 'cash_on_arrival',
              isRecommended: true,
              onTap: () => setState(() => _paymentMethod = 'cash_on_arrival'),
            ),
            const SizedBox(height: 8),
            _PaymentCard(
              title: 'بطاقة بنكية / فيزا وميزة',
              subtitle: 'دفع إلكتروني فوري ومؤمّن',
              icon: Icons.credit_card_rounded,
              isSelected: _paymentMethod == 'card',
              onTap: () => setState(() => _paymentMethod = 'card'),
            ),
            const SizedBox(height: 8),
            _PaymentCard(
              title: 'إنستاباي / تحويل بنكي سريع',
              subtitle: 'تحويل فوري وآمن عبر InstaPay أو تطبيقك البنكي',
              icon: Icons.bolt_rounded,
              isSelected: _paymentMethod == 'instapay',
              onTap: () => setState(() => _paymentMethod = 'instapay'),
            ),
            const SizedBox(height: 18),

            // ── 6. Transparent Cost Breakdown ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                children: [
                  _CostRow(
                    label: 'قيمة الإيجار ($_daysCount يوم)',
                    amount: _totalAmount,
                  ),
                  const SizedBox(height: 8),
                  _CostRow(
                    label: 'رسوم حماية المنصة (${(_commissionRate * 100).toStringAsFixed(0)}%)',
                    amount: _commission,
                  ),
                  const SizedBox(height: 8),
                  _CostRow(
                    label: 'تأمين مسترد عند الإخلاء',
                    amount: _fairDeposit,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: context.borderColor),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الإجمالي النهائي',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_totalWithCommission.round()} ج.م',
                        style: TextStyle(
                          color: context.accentColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          border: Border(top: BorderSide(color: context.borderColor)),
        ),
        child: GradientButton(
          text: 'تأكيد طلب الحجز ⚡',
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _confirmBooking,
          icon: Icons.check_circle_outline_rounded,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 76,
      height: 76,
      color: Colors.grey.withValues(alpha: 0.1),
      child: const Icon(Icons.apartment_rounded, color: Colors.grey, size: 28),
    );
  }

  Widget _buildBlockedScreen(BuildContext context, BookingEligibility eligibility) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('الحجز غير متاح', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                eligibility.isOwnProperty
                    ? 'هذا العقار مسجل باسمك!'
                    : 'حساب تاجر / مالك عقار 🚫',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                eligibility.isOwnProperty
                    ? 'أنت المالك المسجل لهذا العقار، ولا يمكن إجراء حجوزات عليه من حساب المالك نفسه.\nيمكنك إدارة العقار ومتابعة طلبات الحجز من لوحة التحكم.'
                    : 'حسابات أصحاب العقارات والتجار في منصة سكني مخصصة لإدارة وتأجير العقارات فقط ولا يُسمح لها بإجراء حجوزات داخل المنصة لمنع أي تعارض مصالح.\n\nلإجراء حجز، يرجى التبديل إلى حساب مستأجر.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  text: 'الذهاب للوحة تحكم المالك 📊',
                  height: 48,
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                ),
              ),
              if (eligibility.isMerchantRestricted) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: context.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'تسجيل الخروج والتبديل لمستأجر',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () async {
                      final authCubit = context.read<AuthCubit?>();
                      final authProv = context.read<AuthProvider?>();
                      final nav = Navigator.of(context);
                      try {
                        await authCubit?.logout();
                      } catch (_) {}
                      try {
                        await authProv?.logout();
                      } catch (_) {}
                      nav.pushNamedAndRemoveUntil(
                        '/login',
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'الرجوع للخلف',
                  style: TextStyle(color: context.textSecondary, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String title;
  final DateTime date;
  final VoidCallback onTap;

  const _DateBox({
    required this.title,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: context.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: 16, color: context.accentColor),
                const SizedBox(width: 6),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
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

class _PaymentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  const _PaymentCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    this.isRecommended = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? context.accentColor.withValues(alpha: 0.08) : context.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? context.accentColor : context.borderColor,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? context.accentColor.withValues(alpha: 0.15) : context.surfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? context.accentColor : context.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.accentColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'الأكثر طلباً',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: context.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? context.accentColor : context.borderColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final double amount;

  const _CostRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: context.textSecondary, fontSize: 13),
        ),
        Text(
          '${amount.round()} ج.م',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
