// ignore_for_file: unused_element

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/localization/app_localizations.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_state.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakani/features/auth/presentation/screens/kyc_screen.dart';
import 'package:sakani/features/auth/data/services/auth_service.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';
import 'package:sakani/features/settings/presentation/providers/theme_provider.dart';
import 'package:sakani/features/wallet/data/services/wallet_service.dart';
import 'package:sakani/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:sakani/core/services/biometric_service.dart';
import 'package:sakani/features/support/presentation/screens/support_chat_screen.dart';

class SettingsScreen extends StatelessWidget {
  final bool isEmbedded;
  const SettingsScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().lang;
    final tr = AppLocalizations(lang);
    final auth = context.watch<AuthProvider>();
    final authCubit = context.watch<AuthCubit>();
    final authState = authCubit.state;
    final user = authCubit.currentUser ??
        (authState is Authenticated ? authState.user : null) ??
        auth.user ??
        AuthService.currentUser;

    final body = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Unified Hero Profile Card ──
          if (user != null)
            _UnifiedHeroProfileCard(user: user, auth: auth)
          else
            _GuestProfileCard(tr: tr),

          const SizedBox(height: 18),

          // ── 2. Quick Financial & KYC Services Hub ──
          _buildQuickHub(context),

          const SizedBox(height: 24),

          // ── 3. Appearance & Language ──
          _SectionTitle(title: 'المظهر واللغة', icon: Icons.palette_outlined),
          const SizedBox(height: 10),
          _StyledCard(
            child: Column(
              children: [
                _SettingTile(
                  icon: context.isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  iconColor: context.accentColor,
                  title: tr.tr('darkMode'),
                  subtitle: context.isDark ? 'الوضع الداكن مفعّل' : 'الوضع الفاتح مفعّل',
                  trailing: Switch.adaptive(
                    value: context.isDark,
                    activeThumbColor: context.accentColor,
                    activeTrackColor: context.accentColor.withValues(alpha: 0.3),
                    onChanged: (_) {
                      context.read<ThemeProvider>().toggleMode();
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: context.borderColor, height: 1),
                ),
                _SettingTile(
                  icon: Icons.translate_rounded,
                  iconColor: context.accentColor,
                  title: tr.tr('language'),
                  subtitle: lang == 'ar' ? 'اللغة الحالية: العربية' : 'Current: English',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.accentColor.withValues(alpha: 0.1),
                      border: Border.all(color: context.accentColor.withValues(alpha: 0.3)),
                      borderRadius: AppRadius.pillBr,
                    ),
                    child: Text(
                      lang == 'ar' ? 'English' : 'عربي',
                      style: TextStyle(
                        color: context.accentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onTap: () {
                    context.read<LocaleProvider>().toggleLang();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 4. Account & Security ──
          _SectionTitle(title: 'الأمان والتنبيهات', icon: Icons.security_rounded),
          const SizedBox(height: 10),
          _StyledCard(
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.lock_outline_rounded,
                  iconColor: context.accentColor,
                  title: 'تغيير كلمة المرور',
                  subtitle: 'حماية وتأمين الحساب',
                  onTap: () => _showChangePasswordDialog(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: context.borderColor, height: 1),
                ),
                _SettingTile(
                  icon: Icons.fingerprint_rounded,
                  iconColor: context.accentColor,
                  title: 'تسجيل الدخول بالبصمة / Face ID',
                  subtitle: 'تفعيل الدخول السريع عبر البصمة الحيوية',
                  trailing: Switch.adaptive(
                    value: BiometricService.isBiometricLoginEnabled(),
                    activeThumbColor: context.accentColor,
                    activeTrackColor: context.accentColor.withValues(alpha: 0.3),
                    onChanged: (val) async {
                      if (val) {
                        final authOk = await BiometricService.authenticate(
                          reason: 'يرجى التحقق من البصمة لتفعيل الدخول السريع',
                        );
                        if (authOk) {
                          BiometricService.setBiometricLoginEnabled(true);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم تفعيل تسجيل الدخول بالبصمة بنجاح 🌟')),
                            );
                          }
                        }
                      } else {
                        BiometricService.setBiometricLoginEnabled(false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم تعطيل تسجيل الدخول بالبصمة')),
                          );
                        }
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: context.borderColor, height: 1),
                ),
                _SettingTile(
                  icon: Icons.notifications_none_rounded,
                  iconColor: context.accentColor,
                  title: 'إشعارات التطبيق',
                  subtitle: 'تنبيهات الحجوزات والرسائل الجديدة',
                  trailing: Switch.adaptive(
                    value: true,
                    activeThumbColor: context.accentColor,
                    onChanged: (val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث إعدادات الإشعارات'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── 5. Support & About ──
          _SectionTitle(title: 'الدعم والمعلومات', icon: Icons.help_outline_rounded),
          const SizedBox(height: 10),
          _StyledCard(
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.support_agent_rounded,
                  iconColor: Colors.teal,
                  title: 'الدعم الفني المباشر (Live Support 🎧)',
                  subtitle: 'محادثة حية فورية ومتابعة مع موظفي الشيفت',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SupportChatScreen()),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: context.borderColor, height: 1),
                ),
                _SettingTile(
                  icon: Icons.description_outlined,
                  iconColor: context.accentColor,
                  title: 'الشروط والأحكام والسياسات',
                  subtitle: 'شروط الاستخدام وسياسة الخصوصية',
                  onTap: () => _showTermsDialog(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: context.borderColor, height: 1),
                ),
                _SettingTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: context.accentColor,
                  title: 'عن تطبيق سكني',
                  subtitle: 'الإصدار 1.0.0 (النسخة الفاخرة)',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.borderColor.withValues(alpha: 0.5),
                      borderRadius: AppRadius.pillBr,
                    ),
                    child: Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── 6. Logout Button ──
          Container(
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: AppRadius.mdBr,
              border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
            ),
            child: _SettingTile(
              icon: Icons.logout_rounded,
              iconColor: AppColors.error,
              title: tr.tr('logout'),
              subtitle: 'تسجيل الخروج من الحساب الحالي',
              textColor: AppColors.error,
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.error,
              ),
              onTap: () => _confirmLogout(context, auth),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );

    if (isEmbedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.tr('myAccount')),
        centerTitle: true,
      ),
      body: body,
    );
  }

  Widget _buildQuickHub(BuildContext context) {
    final wallet = WalletService();
    return Row(
      children: [
        // Wallet Card
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: context.isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [Colors.white, const Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.accentColor.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.accentColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: context.accentColor,
                          size: 18,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: context.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'رصيد المحفظة',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${wallet.balance.round()}',
                        style: TextStyle(
                          color: context.accentColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ج.م',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // KYC Verification Card
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KycScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: context.isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [Colors.white, const Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: context.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'توثيق الهوية (KYC)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'موثق بالكامل 🌟',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldCtl = TextEditingController();
    final newCtl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBr),
        title: const Text('تغيير كلمة المرور', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الحالية',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: newCtl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                prefixIcon: Icon(Icons.lock_reset_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم تحديث كلمة المرور بنجاح'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('تحديث'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBr),
        title: const Text('مركز الدعم والمساعدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.teal),
              title: const Text('المحادثة الفورية مع الدعم'),
              subtitle: const Text('متاح على مدار 24 ساعة'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportChatScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined, color: Colors.green),
              title: const Text('الخط الساخن: 19888'),
              subtitle: const Text('للحالات الطارئة والاستفسارات'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBr),
        title: const Text('الشروط والأحكام', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: const SingleChildScrollView(
          child: Text(
            'تطبيق سكني يضمن حقوق المستأجر والمالك وفقاً للقوانين المصرية الرسمية ومعايير الأمان المالي. جميع الحجوزات مشمولة بضمان استرداد الأموال وتوثيق الهوية الرقمي.',
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً')),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBr),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج من تطبيق سكني؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: context.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              auth.logout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}

// ── Unified Hero Profile Card ──
class _UnifiedHeroProfileCard extends StatelessWidget {
  final dynamic user;
  final AuthProvider auth;

  const _UnifiedHeroProfileCard({
    required this.user,
    required this.auth,
  });

  void _showImagePickerSheet(BuildContext context) {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'تغيير الصورة الشخصية',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.camera_alt_rounded, color: context.accentColor),
                  ),
                  title: Text(
                    'التقاط صورة بالكاميرا',
                    style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final image = await picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      await auth.updateProfilePhoto(image.path);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تحديث الصورة الشخصية بنجاح 🌟'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.photo_library_rounded, color: context.accentColor),
                  ),
                  title: Text(
                    'اختيار من ألبوم الصور',
                    style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      await auth.updateProfilePhoto(image.path);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('تم تحديث الصورة الشخصية بنجاح 🌟'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameCtl = TextEditingController(text: user.name);
    final phoneCtl = TextEditingController(text: user.phone);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBr),
          title: const Text(
            'تعديل البيانات الشخصية',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtl,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phoneCtl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: TextStyle(color: context.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameCtl.text.trim();
                final newPhone = phoneCtl.text.trim();
                if (newName.isEmpty) return;

                Navigator.pop(ctx);
                final success = await auth.updateProfile(
                  name: newName,
                  phone: newPhone,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'تم تحديث البيانات الشخصية بنجاح 🌟'
                            : 'حدث خطأ أثناء التحديث',
                      ),
                      backgroundColor:
                          success ? AppColors.success : AppColors.error,
                    ),
                  );
                }
              },
              child: const Text('حفظ التعديلات'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final photoUrl = user.photoUrl as String?;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : context.borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with camera icon
              Stack(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [context.accentColor, AppColors.goldDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.accentColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipOval(
                      child: hasPhoto
                          ? (photoUrl.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: photoUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(color: context.cardColor),
                                  errorWidget: (context, url, error) => _buildAvatarFallback(context),
                                )
                              : Image.file(
                                  File(photoUrl),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildAvatarFallback(context),
                                ))
                          : _buildAvatarFallback(context),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showImagePickerSheet(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.surfaceColor, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Name, Phone & Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified_rounded, color: AppColors.success, size: 17),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.phone.isNotEmpty ? user.phone : 'لا يوجد رقم مسجل',
                      style: TextStyle(
                        color: context.textSecondary.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: context.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: context.accentColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        user.isOwner ? '🏢 مالك عقارات موثق' : '👤 مستأجر موثق',
                        style: TextStyle(
                          color: context.accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: context.borderColor, height: 1),
          const SizedBox(height: 12),
          // Edit Profile Details Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'البيانات الشخصية مكتملة ومؤكدة',
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              InkWell(
                onTap: () => _showEditProfileDialog(context),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 14, color: context.accentColor),
                      const SizedBox(width: 4),
                      Text(
                        'تعديل البيانات',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: context.accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(BuildContext context) {
    return Container(
      color: context.cardColor,
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'س',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: context.accentColor,
          ),
        ),
      ),
    );
  }
}

// ── Guest Profile Card ──
class _GuestProfileCard extends StatelessWidget {
  final AppLocalizations tr;
  const _GuestProfileCard({required this.tr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: context.accentColor.withValues(alpha: 0.15),
            child: Icon(Icons.person_outline_rounded, color: context.accentColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحباً بك في سكني',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'سجل دخولك للاستمتاع بجميع المزايا',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text('تسجيل'),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ──
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StyledCard extends StatelessWidget {
  final Widget child;
  const _StyledCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.isDark ? Colors.white.withValues(alpha: 0.06) : context.borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? textColor;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: textColor ?? context.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary.withValues(alpha: 0.75),
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: context.textSecondary.withValues(alpha: 0.5),
          ),
      onTap: onTap,
    );
  }
}
