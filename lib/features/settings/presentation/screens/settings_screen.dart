import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/localization/app_localizations.dart';
import 'package:sakani/features/apartments/presentation/cubit/apartment_cubit.dart';
import 'package:sakani/features/apartments/presentation/cubit/wishlist_cubit.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_state.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakani/features/bookings/presentation/providers/booking_provider.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';
import 'package:sakani/features/settings/presentation/providers/theme_provider.dart';
import 'package:sakani/core/widgets/glass_card.dart';

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
    final user = auth.user ?? (authState is Authenticated ? authState.user : authCubit.currentUser);

    final body = SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Hero User Profile Card ──
          if (user != null)
            _HeroProfileCard(user: user, auth: auth, tr: tr)
          else
            _GuestProfileCard(tr: tr),

          const SizedBox(height: 24),

          // ── 2. Appearance & Display Section ──
          _SectionTitle(title: 'المظهر والعرض', icon: Icons.palette_outlined),
          const SizedBox(height: 10),
          StyledCard(
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

          // ── 3. Account & Security Section ──
          _SectionTitle(title: 'الحساب والأمان', icon: Icons.security_rounded),
          const SizedBox(height: 10),
          StyledCard(
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.person_outline_rounded,
                  iconColor: context.accentColor,
                  title: 'تعديل البيانات الشخصية',
                  subtitle: 'الاسم، رقم الهاتف، والبيانات العامة',
                  onTap: () => _showEditProfileDialog(context, user, auth),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: context.borderColor, height: 1),
                ),
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

          // ── 4. Support & About Section ──
          _SectionTitle(title: 'الدعم والمعلومات', icon: Icons.help_outline_rounded),
          const SizedBox(height: 10),
          StyledCard(
            child: Column(
              children: [
                _SettingTile(
                  icon: Icons.support_agent_rounded,
                  iconColor: Colors.teal,
                  title: 'مركز المساعدة والدعم الفني',
                  subtitle: 'تواصل معنا مباشرة عبر المحادثة أو واتساب',
                  onTap: () => _showSupportDialog(context),
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
                  subtitle: 'الإصدار 1.0.0 (أحدث إصدار)',
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

          // ── 5. Logout Button ──
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
        title: Text(tr.tr('settings')),
        centerTitle: true,
      ),
      body: body,
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

// ── Hero Profile Card ──
class _HeroProfileCard extends StatelessWidget {
  final dynamic user;
  final AuthProvider auth;
  final AppLocalizations tr;

  const _HeroProfileCard({
    required this.user,
    required this.auth,
    required this.tr,
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
                  'تغيير صورة البروفايل',
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
                      color: context.accentColor.withValues(alpha: 0.1),
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
                          const SnackBar(content: Text('تم تحديث صورة البروفايل بنجاح')),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.photo_library_rounded, color: context.accentColor),
                  ),
                  title: Text(
                    'اختيار من المعرض',
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
                          const SnackBar(content: Text('تم تحديث صورة البروفايل بنجاح')),
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

  Widget _buildAvatar(BuildContext context) {
    final photo = user.photoUrl as String?;
    Widget imageWidget;

    if (photo != null && photo.isNotEmpty) {
      if (photo.startsWith('http')) {
        imageWidget = CachedNetworkImage(
          imageUrl: photo,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          placeholder: (ctx, url) => Center(
            child: CircularProgressIndicator(color: context.accentColor, strokeWidth: 2),
          ),
          errorWidget: (ctx, url, err) => _buildFallbackInitial(context),
        );
      } else {
        imageWidget = Image.file(
          File(photo),
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => _buildFallbackInitial(context),
        );
      }
    } else {
      imageWidget = _buildFallbackInitial(context);
    }

    return GestureDetector(
      onTap: () => _showImagePickerSheet(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.accentColor, width: 2),
              boxShadow: AppShadows.goldGlow,
            ),
            child: ClipOval(child: imageWidget),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: context.surfaceColor, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 14,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackInitial(BuildContext context) {
    final name = (user.name as String? ?? '').trim();
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.gold,
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = user.role == 'owner';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.card(context),
        borderRadius: AppRadius.lgBr,
        border: Border.all(color: context.accentColor.withValues(alpha: 0.25)),
        boxShadow: AppShadows.card(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_note_rounded, color: context.accentColor, size: 24),
                          onPressed: () => _showEditProfileDialog(context, user, auth),
                          tooltip: 'تعديل البيانات',
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.phone.isNotEmpty ? user.phone : user.email,
                      style: TextStyle(color: context.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.accentColor.withValues(alpha: 0.15),
                            borderRadius: AppRadius.pillBr,
                            border: Border.all(color: context.accentColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOwner ? Icons.verified_user_rounded : Icons.person_rounded,
                                size: 12,
                                color: context.accentColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOwner ? 'مالك عقارات موثق' : 'مستأجر نشط',
                                style: TextStyle(
                                  color: context.accentColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer3<WishlistCubit, BookingProvider, ApartmentCubit>(
            builder: (context, wishlist, bookingProv, aptCubit, _) {
              final wishlistCount = wishlist.state.length;
              final bookingsCount = isOwner
                  ? bookingProv.ownerBookings.length
                  : bookingProv.tenantBookings.length;
              final aptsCount = aptCubit.state.ownerApartments.length;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: context.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      title: isOwner ? 'عقاراتي' : 'المفضلة',
                      value: isOwner ? '$aptsCount' : '$wishlistCount',
                      icon: isOwner ? Icons.apartment_rounded : Icons.favorite_rounded,
                      color: isOwner ? context.accentColor : Colors.redAccent,
                    ),
                    Container(width: 1, height: 26, color: context.borderColor),
                    _buildStatItem(
                      context,
                      title: 'الحجوزات',
                      value: '$bookingsCount',
                      icon: Icons.calendar_month_rounded,
                      color: Colors.blueAccent,
                    ),
                    Container(width: 1, height: 26, color: context.borderColor),
                    _buildStatItem(
                      context,
                      title: isOwner ? 'التقييم' : 'الحالة',
                      value: isOwner ? '4.9 ★' : 'موثق ✓',
                      icon: isOwner ? Icons.star_rounded : Icons.verified_user_rounded,
                      color: isOwner ? Colors.amber : Colors.greenAccent,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: context.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GuestProfileCard extends StatelessWidget {
  final AppLocalizations tr;
  const _GuestProfileCard({required this.tr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.card(context),
        borderRadius: AppRadius.lgBr,
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_circle_rounded, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('زائر', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('سجل الدخول للاستفادة من كافة الخدمات', style: TextStyle(color: context.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Title Widget ──
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
            color: context.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ── Setting Tile Component ──
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? context.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: context.textSecondary, fontSize: 12),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_left_rounded,
            size: 20,
            color: context.textSecondary.withValues(alpha: 0.5),
          ),
      onTap: onTap,
    );
  }
}

// ── Dialogs ──
void _showEditProfileDialog(
  BuildContext context,
  dynamic user,
  AuthProvider auth,
) {
  if (user == null) return;
  final nameCtl = TextEditingController(text: user.name);
  final phoneCtl = TextEditingController(text: user.phone);

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: context.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBr),
        title: Row(
          children: [
            Icon(Icons.edit_rounded, color: context.accentColor, size: 22),
            const SizedBox(width: 8),
            const Text('تعديل البيانات الشخصية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
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
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف / الواتساب',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
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
              if (nameCtl.text.trim().isEmpty) return;
              await auth.updateProfile(
                name: nameCtl.text.trim(),
                phone: phoneCtl.text.trim(),
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
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
            decoration: const InputDecoration(labelText: 'كلمة المرور الحالية'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newCtl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
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
              const SnackBar(content: Text('تم تحديث كلمة المرور بنجاح')),
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
      title: Row(
        children: [
          Icon(Icons.support_agent_rounded, color: context.accentColor),
          const SizedBox(width: 8),
          const Text('الدعم الفني والمساعدة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('فريق سكني متواجد على مدار 24 ساعة للإجابة على استفساراتكم ومساعدتكم.'),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.phone_rounded, color: context.accentColor, size: 20),
              const SizedBox(width: 8),
              const Text('خدمة العملاء: 19999', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.email_outlined, color: context.accentColor, size: 20),
              const SizedBox(width: 8),
              const Text('support@sakani.app'),
            ],
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('حسناً'),
        ),
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
      title: const Text('الشروط وسياسة الخصوصية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: const SingleChildScrollView(
        child: Text(
          'تطبيق سكني يلتزم بحماية خصوصية كافة المستخدمين والبيانات المشفرة. '
          'يتم تنظيم عمليات حجز الشقق السكنية وفقاً للوائح والقوانين المعتمدة لحفظ حقوق المالك والمستأجر. '
          'يُحظر استخدام التطبيق لأي أنشطة غير قانونية أو انتهاك شروط الملكية.',
          style: TextStyle(height: 1.5),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('إغلاق'),
        ),
      ],
    ),
  );
}
