import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/gradient_button.dart';
import 'package:sakani/features/auth/data/services/auth_service.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';

/// حالات صلاحيات الحجز لمنع أي ثغرة أمنية أو حجز غير مصرح به
enum BookingGuardStatus {
  eligible,
  merchantRestricted,
  ownProperty,
  notAuthenticated,
}

/// نتيجة فحص أهلية الحجز
class BookingEligibility {
  final BookingGuardStatus status;
  final String? message;

  const BookingEligibility({
    required this.status,
    required this.message,
  });

  bool get isEligible => status == BookingGuardStatus.eligible;
  bool get isMerchantRestricted => status == BookingGuardStatus.merchantRestricted;
  bool get isOwnProperty => status == BookingGuardStatus.ownProperty;
  bool get isNotAuthenticated => status == BookingGuardStatus.notAuthenticated;
}

/// جدار الحماية الأمني لمنع التجار وأصحاب العقارات من إجراء حجوزات (Anti-Merchant Booking Shield)
class BookingSecurityGuard {
  /// التحقق مما إذا كان المستخدم الحالي مسجلاً كصاحب عقار أو تاجر
  static bool isMerchantOrOwner(BuildContext context) {
    try {
      final cubitUser = context.read<AuthCubit?>()?.currentUser;
      if (cubitUser != null && (cubitUser.isOwner || cubitUser.role == 'owner')) {
        return true;
      }
    } catch (_) {}

    try {
      final provUser = context.read<AuthProvider?>()?.user;
      if (provUser != null && (provUser.isOwner || provUser.role == 'owner')) {
        return true;
      }
    } catch (_) {}

    final direct = AuthService.currentUser;
    if (direct != null && (direct.role == 'owner' || direct.isOwner)) {
      return true;
    }

    return false;
  }

  /// التحقق مما إذا كان العقار مسجلاً باسم المستخدم الحالي
  static bool isOwnApartment(BuildContext context, String apartmentOwnerId) {
    if (apartmentOwnerId.trim().isEmpty) return false;
    final uid = getCurrentUserId(context);
    return uid != null && uid.isNotEmpty && uid == apartmentOwnerId;
  }

  /// جلب معرف المستخدم النشط حالياً
  static String? getCurrentUserId(BuildContext context) {
    try {
      final cubitUid = context.read<AuthCubit?>()?.currentUser?.uid;
      if (cubitUid != null && cubitUid.isNotEmpty) return cubitUid;
    } catch (_) {}

    try {
      final provUid = context.read<AuthProvider?>()?.user?.uid;
      if (provUid != null && provUid.isNotEmpty) return provUid;
    } catch (_) {}

    final directUid = AuthService.currentUser?.uid;
    if (directUid != null && directUid.isNotEmpty) return directUid;

    return null;
  }

  /// التحقق من حالة تسجيل الدخول
  static bool isAuthenticated(BuildContext context) {
    return getCurrentUserId(context) != null;
  }

  /// الفحص الشامل لأهلية الحجز
  static BookingEligibility checkEligibility({
    required BuildContext context,
    required String apartmentOwnerId,
  }) {
    if (!isAuthenticated(context)) {
      return const BookingEligibility(
        status: BookingGuardStatus.notAuthenticated,
        message: 'يرجى تسجيل الدخول بحساب مستأجر لإتمام الحجز.',
      );
    }

    if (isOwnApartment(context, apartmentOwnerId)) {
      return const BookingEligibility(
        status: BookingGuardStatus.ownProperty,
        message: 'لا يمكنك حجز عقار مسجل باسمك.',
      );
    }

    if (isMerchantOrOwner(context)) {
      return const BookingEligibility(
        status: BookingGuardStatus.merchantRestricted,
        message:
            'عذراً، حسابات أصحاب العقارات والتجار مخصصة لإدارة وتأجير العقارات فقط ولا يمكنها إجراء حجوزات.',
      );
    }

    return const BookingEligibility(
      status: BookingGuardStatus.eligible,
      message: null,
    );
  }

  /// التأكد من الصلاحية مع عرض التنبيه المناسب تلقائياً في حال الرفض
  static Future<bool> ensureCanBook(
    BuildContext context, {
    required String apartmentOwnerId,
    required String apartmentTitle,
  }) async {
    final eligibility = checkEligibility(
      context: context,
      apartmentOwnerId: apartmentOwnerId,
    );

    if (eligibility.isEligible) {
      return true;
    }

    await showBlockedModal(
      context,
      eligibility: eligibility,
      apartmentTitle: apartmentTitle,
    );
    return false;
  }

  /// عرض نافذة توعوية وأمنية تشرح سبب الحظر وتوفر الخيارات البديلة المناسبة
  static Future<void> showBlockedModal(
    BuildContext context, {
    required BookingEligibility eligibility,
    required String apartmentTitle,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BlockedBottomSheet(
        eligibility: eligibility,
        apartmentTitle: apartmentTitle,
      ),
    );
  }
}

class _BlockedBottomSheet extends StatelessWidget {
  final BookingEligibility eligibility;
  final String apartmentTitle;

  const _BlockedBottomSheet({
    required this.eligibility,
    required this.apartmentTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: eligibility.isMerchantRestricted
                ? AppColors.error.withValues(alpha: 0.5)
                : context.accentColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icon Badge
            _buildBadge(context),

            const SizedBox(height: 18),

            // Title
            Text(
              _getTitle(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 10),

            // Description
            Text(
              _getDescription(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 13.5,
                height: 1.55,
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            ..._buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    if (eligibility.isMerchantRestricted) {
      return Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.block_rounded,
          color: AppColors.error,
          size: 40,
        ),
      );
    } else if (eligibility.isOwnProperty) {
      return Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.home_work_rounded,
          color: AppColors.gold,
          size: 40,
        ),
      );
    } else {
      return Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: context.accentColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: context.accentColor.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
        child: Icon(
          Icons.lock_person_rounded,
          color: context.accentColor,
          size: 40,
        ),
      );
    }
  }

  String _getTitle() {
    if (eligibility.isMerchantRestricted) {
      return 'حساب تاجر / مالك عقار 🚫';
    } else if (eligibility.isOwnProperty) {
      return 'هذا العقار مسجل باسمك 🏠';
    } else {
      return 'تسجيل الدخول مطلوب 🔑';
    }
  }

  String _getDescription() {
    if (eligibility.isMerchantRestricted) {
      return 'حسابات أصحاب العقارات والتجار في منصة سكني مخصصة لعرض وإدارة العقارات وتأجيرها واستقبال الحجوزات.\n\nوفقاً لسياسة الأمان ومنع تعارض المصالح، لا يُسمح بإجراء حجوزات من حسابات التجار. لإتمام حجز، يُرجى التبديل لحساب مستأجر.';
    } else if (eligibility.isOwnProperty) {
      return 'أنت المالك المسجل لهذا العقار "$apartmentTitle". لا يمكنك حجز عقارك الخاص، ولكن يمكنك إدارة أسعاره وتوفر الحجوزات من لوحة التحكم.';
    } else {
      return 'لإتمام حجز هذا العقار، يرجى تسجيل الدخول بحساب مستأجر أو إنشاء حساب جديد للمتابعة.';
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    if (eligibility.isMerchantRestricted) {
      return [
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'الذهاب للوحة تحكم المالك 📊',
            height: 48,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: context.borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text(
              'تسجيل الخروج والتبديل لحساب مستأجر',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            onPressed: () async {
              final authCubit = context.read<AuthCubit?>();
              final authProv = context.read<AuthProvider?>();
              final nav = Navigator.of(context);
              nav.pop();
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
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'إلغاء',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
        ),
      ];
    } else if (eligibility.isOwnProperty) {
      return [
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'إدارة العقار في لوحة التحكم 🛠️',
            height: 48,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'إغلاق',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
        ),
      ];
    } else {
      return [
        SizedBox(
          width: double.infinity,
          child: GradientButton(
            text: 'تسجيل الدخول الآن 🔑',
            height: 48,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'إلغاء',
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
        ),
      ];
    }
  }
}
