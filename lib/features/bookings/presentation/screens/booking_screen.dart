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
import 'package:sakani/features/wallet/data/services/wallet_service.dart';
import 'package:sakani/core/widgets/notifications_bottom_sheet.dart';
import 'package:sakani/core/widgets/trust_score_badge.dart';
import 'package:sakani/core/services/platform_config_service.dart';
import 'package:sakani/core/services/fair_deposit_service.dart';
import 'package:sakani/core/security/security_sanitizer.dart';
import 'package:sakani/core/localization/app_localizations.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';

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
  String _paymentMethod = 'wallet'; // 'wallet', 'card', 'vodafone', 'fawry'

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
        : (_periodType == 'سنوي' ? widget.apartment.yearlyPrice : widget.apartment.monthlyPrice),
    daysCount: _daysCount,
    apartmentSpecifiedDeposit: widget.apartment.securityDeposit,
  );

  double get _totalWithCommission =>
      _totalAmount + _commission + _fairDeposit;

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

    // Check Wallet balance if wallet method is selected
    if (_paymentMethod == 'wallet') {
      final walletService = WalletService();
      if (walletService.balance < _totalWithCommission) {
        AppSnackbar.show(
          context,
          message: 'عذراً، رصيد المحفظة الحالي (${walletService.balance.toStringAsFixed(0)} ج.م) غير كافٍ. يرجى شحن المحفظة أو اختيار وسيلة دفع أخرى.',
          type: ToastType.error,
        );
        return;
      }
    }

    final bookingProv = context.read<BookingProvider>();
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final booking = Booking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      apartmentId: widget.apartment.id,
      ownerId: widget.apartment.ownerId,
      tenantId: user.uid,
      tenantName: SecuritySanitizer.sanitizeSql(user.name),
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
    final success = await bookingProv.createBooking(booking);
    if (!mounted) return;
    if (success) {
      if (_paymentMethod == 'wallet') {
        await WalletService().deduct(
          amount: _totalWithCommission,
          title: 'حجز مؤكد: ${widget.apartment.title}',
          description: 'تم حجز المبلغ في حساب الضمان (Escrow) لتأكيد الإيجار.',
        );
      }

      if (!mounted) return;

      // Add real-time notification
      NotificationsBottomSheet.addNotification(
        title: 'تم إرسال طلب الحجز بنجاح 🏡',
        body: 'حجزك لشقة "${widget.apartment.title}" بقيمة ${_totalWithCommission.round()} ج.م مؤمّن بحساب الضمان المالي.',
        icon: Icons.verified_rounded,
        color: AppColors.success,
      );

      try {
        context.read<BookingCubit>().loadTenantBookings(user.uid);
      } catch (_) {}
      AppSnackbar.show(
        context,
        message: 'تم إرسال طلب الحجز بنجاح والمبلغ محمي بحساب الضمان 🛡️',
        type: ToastType.success,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().lang;
    final tr = AppLocalizations(lang);
    return Scaffold(
      appBar: AppBar(title: Text(tr.tr('bookingTitle'))),
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
              SectionHeader(title: tr.tr('rentalType')),
              Row(
                children: widget.apartment.availableRentTypes.map((type) {
                  final selected = _periodType == type;
                  final index = widget.apartment.availableRentTypes.indexOf(type);
                  final isFirst = index == 0;
                  final isLast = index == widget.apartment.availableRentTypes.length - 1;
                  final displayType = type == 'يومي'
                      ? tr.tr('daily')
                      : (type == 'سنوي' ? tr.tr('yearly') : tr.tr('monthly'));
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
                                  displayType,
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
                                      : widget.apartment.yearlyPrice} ${tr.tr('currency')}',
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
              SectionHeader(title: tr.tr('bookingDate')),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: tr.tr('from'),
                      date: _startDate,
                      onTap: () => _pickDate(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: tr.tr('to'),
                      date: _endDate,
                      onTap: () => _pickDate(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: context.accentColor.withValues(alpha: 0.08),
                  borderRadius: AppRadius.smBr,
                  border: Border.all(color: context.accentColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event_available_rounded, size: 18, color: context.accentColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lang == 'ar'
                            ? 'المدة المحددة: $_daysCount يوم ${_periodType == 'شهري' && _daysCount >= 30 ? '(${(_daysCount / 30).toStringAsFixed(1)} شهر)' : ''} • يتم احتساب السعر تلقائياً'
                            : 'Selected Duration: $_daysCount days ${_periodType == 'شهري' && _daysCount >= 30 ? '(${(_daysCount / 30).toStringAsFixed(1)} months)' : ''} • Price auto-calculated',
                        style: TextStyle(color: context.accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
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
                    _SummaryRow(
                      label: '${tr.tr('baseRent')} ($_daysCount ${tr.tr('days')})',
                      amount: _totalAmount,
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: '${tr.tr('platformCommission')} (${(_commissionRate * 100).toStringAsFixed(0)}%)',
                      amount: _commission,
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: '${tr.tr('fairDeposit')} (${FairDepositService.getRegionTier(widget.apartment.city)})',
                      amount: _fairDeposit,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        color: context.accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    _SummaryRow(
                      label: tr.tr('totalDue'),
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
                              lang == 'ar'
                                  ? 'يتم احتساب التأمين المالي بعدالة وفقاً للمنطقة الجغرافية ونوع الإيجار، ويحفظ بأمان في محفظة الضمان (Escrow) المستردة بالكامل عند الإخلاء.'
                                  : 'Fair security deposit is estimated by regional tier and rental model, securely kept in Escrow and refunded upon checkout.',
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
              const SizedBox(height: 18),

              // ── Trust Score & E-Contract Card ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: AppRadius.mdBr,
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const TrustScoreBadge(score: 99.0, completedDeals: 38, rating: 4.95),
                        const Spacer(),
                        Text(
                          tr.tr('verifiedUser'),
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.accentColor,
                          side: BorderSide(color: context.accentColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: AppRadius.smBr),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/contract',
                            arguments: {
                              'apartment': widget.apartment,
                              'totalAmount': _totalAmount,
                              'periodType': _periodType,
                              'startDate': _startDate,
                              'endDate': _endDate,
                            },
                          );
                        },
                        icon: const Icon(Icons.draw_rounded, size: 18),
                        label: Text(
                          tr.tr('previewContract'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Payment Methods & Escrow Guarantee ──
              SectionHeader(title: tr.tr('paymentMethod')),
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.15),
                      AppColors.goldDark.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: AppRadius.mdBr,
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: AppColors.gold, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tr.tr('escrowBadge')} 🛡️',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tr.tr('escrowDescription'),
                            style: TextStyle(
                              color: context.textSecondary,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // List of payment options
              _PaymentOptionTile(
                icon: Icons.account_balance_wallet_rounded,
                title: tr.tr('walletPay'),
                subtitle: '${lang == 'ar' ? 'رصيدك' : 'Balance'}: ${WalletService().balance.toStringAsFixed(0)} ${tr.tr('currency')}',
                badge: lang == 'ar' ? 'موصى به' : 'Recommended',
                isSelected: _paymentMethod == 'wallet',
                onTap: () => setState(() => _paymentMethod = 'wallet'),
              ),
              const SizedBox(height: 10),
              _PaymentOptionTile(
                icon: Icons.credit_card_rounded,
                title: tr.tr('cardPay'),
                subtitle: lang == 'ar' ? 'دفع إلكتروني آمن ومشفّر' : 'Encrypted direct card checkout',
                isSelected: _paymentMethod == 'card',
                onTap: () => setState(() => _paymentMethod = 'card'),
              ),
              const SizedBox(height: 10),
              _PaymentOptionTile(
                icon: Icons.phone_android_rounded,
                title: tr.tr('vodafonePay'),
                subtitle: lang == 'ar' ? 'فودافون كاش، أورنج، وي، اتصالات، إنستاباي' : 'Vodafone Cash, Orange, WE, Etisalat, InstaPay',
                isSelected: _paymentMethod == 'vodafone',
                onTap: () => setState(() => _paymentMethod = 'vodafone'),
              ),
              const SizedBox(height: 10),
              _PaymentOptionTile(
                icon: Icons.receipt_long_rounded,
                title: tr.tr('fawryPay'),
                subtitle: lang == 'ar' ? 'سداد نقدي بكود مرجعي عبر منافذ فوري' : 'Cash payment at any Fawry retail point in Egypt',
                isSelected: _paymentMethod == 'fawry',
                onTap: () => setState(() => _paymentMethod = 'fawry'),
              ),

              if (_paymentMethod == 'vodafone') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smBr,
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'رقم التحويل للمحفظة: 01029384756 أو معرف إنستاباي: sakani@instapay',
                          style: TextStyle(color: context.textPrimary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_paymentMethod == 'fawry') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: AppRadius.smBr,
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pin_outlined, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'كود السداد عبر فوري: 948 201 55 (صالح لمدة 48 ساعة)',
                          style: TextStyle(color: context.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
            text: tr.tr('confirmBooking'),
            isLoading: prov.isLoading,
            onPressed: prov.isLoading ? null : _book,
            icon: Icons.check_circle_rounded,
          ),
        ),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdBr,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? context.accentColor.withValues(alpha: 0.08)
                : context.cardColor,
            borderRadius: AppRadius.mdBr,
            border: Border.all(
              color: isSelected ? context.accentColor : context.borderColor,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.accentColor.withValues(alpha: 0.2)
                      : context.surfaceColor,
                  borderRadius: AppRadius.smBr,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? context.accentColor : context.textSecondary,
                  size: 22,
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
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.accentColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'موصى به',
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
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? context.accentColor : context.textSecondary.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
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
