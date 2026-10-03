import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';
import 'package:sakani/features/auth/data/models/user_model.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/support/presentation/screens/support_chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class OwnerPendingApprovalScreen extends StatefulWidget {
  const OwnerPendingApprovalScreen({super.key});

  @override
  State<OwnerPendingApprovalScreen> createState() => _OwnerPendingApprovalScreenState();
}

class _OwnerPendingApprovalScreenState extends State<OwnerPendingApprovalScreen> {
  final _inviteCodeCtl = TextEditingController();
  bool _isVerifyingCode = false;

  // Valid official admin invite codes for instant bypass/activation
  static const _validInviteCodes = [
    'SAKANI-OWNER-2026',
    'SAKANI-VIP-ADMIN',
    'SAKANI-ROYAL',
    'ADMIN-PASS-2026',
    'SAKANI-DEV-77',
    'OWNER-VERIFIED',
  ];

  @override
  void dispose() {
    _inviteCodeCtl.dispose();
    super.dispose();
  }

  void _verifyInviteCode() async {
    final code = _inviteCodeCtl.text.trim().toUpperCase();
    if (code.isEmpty) {
      AppSnackbar.show(context, message: 'يرجى إدخال كود الدعوة المعتمد', type: ToastType.error);
      return;
    }

    setState(() => _isVerifyingCode = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    if (_validInviteCodes.contains(code)) {
      final user = context.read<AuthCubit>().currentUser;
      if (user is UserModel) {
        final updated = user.copyWith(
          isApproved: true,
          status: 'active',
          inviteCode: code,
        );
        context.read<AuthCubit>().authRepository.updateProfile(user.uid, updated.toMap());
      }
      
      setState(() => _isVerifyingCode = false);
      AppSnackbar.show(
        context,
        message: 'تم تفعيل حساب المالك بنجاح عبر كود الدعوة المعتمد! 🎉',
        type: ToastType.success,
      );
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
    } else {
      setState(() => _isVerifyingCode = false);
      AppSnackbar.show(
        context,
        message: 'كود الدعوة غير صحيح أو منتهي الصلاحية. تواصل مع الإدارة للحصول على كود جديد.',
        type: ToastType.error,
      );
    }
  }

  void _openWhatsAppSupport() async {
    final user = context.read<AuthCubit>().currentUser;
    final phone = user?.phone ?? '';
    final name = user?.name ?? 'مالك عقار';
    final text = Uri.encodeComponent(
      'مرحباً إدارة سكني، أود طلب تسريع اعتماد حساب المالك الخاص بي:\nالاسم: $name\nالهاتف: $phone\nرقم الطلب: REQ-${user?.uid.substring(0, 6).toUpperCase() ?? "NEW"}',
    );
    final url = Uri.parse('https://wa.me/201097782352?text=$text');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        AppSnackbar.show(context, message: 'رقم واتساب الإدارة: 01097782352', type: ToastType.info);
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.show(context, message: 'رقم واتساب الإدارة: 01097782352', type: ToastType.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final user = context.watch<AuthCubit>().currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'اعتماد حساب المالك',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, color: context.textPrimary, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            icon: Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () async {
              final nav = Navigator.of(context);
              await context.read<AuthCubit>().logout();
              if (mounted) {
                nav.pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Animated Luxury Status Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [Colors.white, const Color(0xFFEFF6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.hourglass_top_rounded,
                          color: Color(0xFFF59E0B),
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_outlined, size: 15, color: Color(0xFFD97706)),
                          const SizedBox(width: 6),
                          Text(
                            'الحساب قيد المراجعة والاعتماد',
                            style: GoogleFonts.tajawal(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'مرحباً بك يا ${user?.name ?? "شريكنا المالك"} 🏢',
                      style: GoogleFonts.tajawal(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: context.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'طلب انضمامك كمالك عقار تم استلامه وتوثيق هويتك بنجاح.\nلضمان معايير الأمان وموثوقية العقارات في سكني، تخضع حسابات الملاك لمراجعة الإدارة قبل التفعيل.',
                      style: GoogleFonts.tajawal(
                        fontSize: 13.5,
                        height: 1.5,
                        color: context.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'رقم طلب التوثيق:',
                            style: GoogleFonts.tajawal(fontSize: 12.5, color: context.textSecondary),
                          ),
                          Text(
                            'REQ-${(user?.uid ?? "123456").substring(0, 6).toUpperCase()}',
                            style: GoogleFonts.tajawal(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: context.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Option 1: Admin Invite Code for Instant Activation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.vpn_key_rounded, size: 20, color: context.accentColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تفعيل فوري بكود دعوة الإدارة',
                                style: GoogleFonts.tajawal(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                ),
                              ),
                              Text(
                                'إذا استلمت كود دعوة رسمي من إدارة سكني',
                                style: GoogleFonts.tajawal(
                                  fontSize: 11.5,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _inviteCodeCtl,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.tajawal(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: context.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'مثال: SAKANI-OWNER-2026',
                        hintStyle: GoogleFonts.tajawal(
                          fontSize: 13,
                          letterSpacing: 0,
                          color: context.textSecondary.withValues(alpha: 0.5),
                        ),
                        prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: context.accentColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isVerifyingCode ? null : _verifyInviteCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.accentColor,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isVerifyingCode
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.verified_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'تحقق وتفعيل الحساب فورياً',
                                    style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 14),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Option 2: Contact Support for instant approval
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.headset_mic_rounded, size: 20, color: AppColors.success),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تسريع الاعتماد مع الدعم الفني',
                                style: GoogleFonts.tajawal(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                ),
                              ),
                              Text(
                                'تواصل مباشرة مع فريق الإدارة لاعتماد حسابك',
                                style: GoogleFonts.tajawal(
                                  fontSize: 11.5,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SupportChatScreen()),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 17),
                            label: Text(
                              'شات الدعم',
                              style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: context.accentColor),
                              foregroundColor: context.accentColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openWhatsAppSupport,
                            icon: const Icon(Icons.phone_in_talk_rounded, size: 17),
                            label: Text(
                              'واتساب الإدارة',
                              style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Logout Button
              TextButton.icon(
                onPressed: () async {
                  final nav = Navigator.of(context);
                  await context.read<AuthCubit>().logout();
                  if (context.mounted) {
                    nav.pushNamedAndRemoveUntil('/login', (_) => false);
                  }
                },
                icon: Icon(Icons.arrow_back_rounded, size: 16, color: context.textSecondary),
                label: Text(
                  'العودة لشاشة الدخول والتبديل لحساب آخر',
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
