import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/services/kyc_service.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_state.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakani/features/auth/presentation/screens/kyc_screen.dart';
import 'package:sakani/features/wallet/data/services/wallet_service.dart';
import 'package:sakani/features/wallet/presentation/screens/wallet_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ImagePicker _picker = ImagePicker();

  void _showImagePickerSheet(AuthProvider auth) {
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
                  style: GoogleFonts.tajawal(
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
                    style: GoogleFonts.tajawal(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final image = await _picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      await auth.updateProfilePhoto(image.path);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم تحديث الصورة الشخصية بنجاح', style: GoogleFonts.tajawal()),
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
                    style: GoogleFonts.tajawal(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final image = await _picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                    );
                    if (image != null) {
                      await auth.updateProfilePhoto(image.path);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('تم تحديث الصورة الشخصية بنجاح', style: GoogleFonts.tajawal()),
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

  void _showEditProfileDialog(dynamic user, AuthProvider auth) {
    if (user == null) return;
    final nameCtl = TextEditingController(text: user.name);
    final phoneCtl = TextEditingController(text: user.phone);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBr),
          title: Text(
            'تعديل البيانات الشخصية',
            style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtl,
                style: GoogleFonts.tajawal(),
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phoneCtl,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.tajawal(),
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف / الواتساب',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء', style: GoogleFonts.tajawal(color: context.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtl.text.trim().isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                await auth.updateProfile(
                  name: nameCtl.text.trim(),
                  phone: phoneCtl.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  setState(() {});
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('تم تحديث البيانات بنجاح', style: GoogleFonts.tajawal()),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: Text('حفظ', style: GoogleFonts.tajawal(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final authCubit = context.watch<AuthCubit>();
    final authState = authCubit.state;
    final user = auth.user ?? (authState is Authenticated ? authState.user : authCubit.currentUser);

    final isOwner = user?.role == 'owner';
    final isVerified = KycService().isVerified;
    final kycData = KycService().currentData;
    final walletBal = WalletService().balance;

    final photo = user?.photoUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الملف الشخصي والحساب',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_note_rounded, color: context.accentColor, size: 26),
            onPressed: () => _showEditProfileDialog(user, auth),
            tooltip: 'تعديل البيانات',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // ── 1. Hero Avatar & Identity Card ──
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showImagePickerSheet(auth),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: context.accentColor, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: context.accentColor.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: (photo != null && photo.isNotEmpty)
                                ? (photo.startsWith('http')
                                    ? CachedNetworkImage(
                                        imageUrl: photo,
                                        fit: BoxFit.cover,
                                        placeholder: (_, _) => Center(
                                          child: CircularProgressIndicator(
                                            color: context.accentColor,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : Image.file(File(photo), fit: BoxFit.cover))
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.gold,
                                    ),
                                    child: Center(
                                      child: Text(
                                        (user?.name != null && user!.name.isNotEmpty)
                                            ? user.name[0].toUpperCase()
                                            : 'U',
                                        style: GoogleFonts.tajawal(
                                          color: Colors.black,
                                          fontSize: 38,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: context.accentColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: context.surfaceColor, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 15,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?.name ?? 'المستخدم',
                    style: GoogleFonts.tajawal(
                      color: context.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: GoogleFonts.tajawal(
                      color: context.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOwner ? Icons.real_estate_agent_rounded : Icons.person_rounded,
                          size: 14,
                          color: context.accentColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOwner ? 'حساب مالك عقارات موثق' : 'حساب مستأجر معتمد',
                          style: GoogleFonts.tajawal(
                            color: context.accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── 2. KYC National ID / Passport Status Card ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isVerified
                    ? AppColors.success.withValues(alpha: 0.1)
                    : context.accentColor.withValues(alpha: 0.1),
                borderRadius: AppRadius.mdBr,
                border: Border.all(
                  color: isVerified
                      ? AppColors.success.withValues(alpha: 0.35)
                      : context.accentColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isVerified ? AppColors.success : context.accentColor)
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVerified ? Icons.verified_user_rounded : Icons.badge_outlined,
                      color: isVerified ? AppColors.success : context.accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVerified ? 'الهوية موثقة رسمياً ✅' : 'توثيق الهوية الرسمية (مطلوب)',
                          style: GoogleFonts.tajawal(
                            color: isVerified ? AppColors.success : context.accentColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isVerified
                              ? 'الرقم: ${kycData.documentNumber} (${kycData.documentType == "national_id" ? "بطاقة قومي" : "جواز سفر"})'
                              : 'ارفع صورة البطاقة أو الباسبور لتأكيد حجوزاتك',
                          style: GoogleFonts.tajawal(
                            color: context.textSecondary,
                            fontSize: 11,
                          ),
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
                    style: TextButton.styleFrom(
                      foregroundColor: isVerified ? AppColors.success : context.accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    child: Text(
                      isVerified ? 'عرض' : 'توثيق الآن',
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 3. Sakani Digital Wallet Quick Card ──
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WalletScreen()),
                );
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.mdBr,
                  border: Border.all(color: context.accentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.accentColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.account_balance_wallet_rounded, color: context.accentColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'محفظة سكني الرقمية',
                            style: GoogleFonts.tajawal(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'الرصيد المتاح: ${walletBal.toInt()} ج.م',
                            style: GoogleFonts.tajawal(
                              color: context.accentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'شحن / تفاصيل',
                        style: GoogleFonts.tajawal(
                          color: const Color(0xFF080C14),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── 4. Full User Data Details Card ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppRadius.mdBr,
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'البيانات التفصيلية للحساب',
                    style: GoogleFonts.tajawal(
                      color: context.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'الاسم الكامل',
                    value: user?.name ?? 'غير محدد',
                  ),
                  Divider(color: context.borderColor, height: 20),
                  _DetailRow(
                    icon: Icons.email_outlined,
                    label: 'البريد الإلكتروني',
                    value: user?.email ?? 'غير محدد',
                  ),
                  Divider(color: context.borderColor, height: 20),
                  _DetailRow(
                    icon: Icons.phone_outlined,
                    label: 'رقم الهاتف / الواتساب',
                    value: (user?.phone != null && user!.phone.isNotEmpty)
                        ? user.phone
                        : 'لم يتم إضافة رقم هاتف بعد',
                  ),
                  Divider(color: context.borderColor, height: 20),
                  _DetailRow(
                    icon: Icons.badge_outlined,
                    label: 'حالة التوثيق (KYC)',
                    value: isVerified ? 'موثق بالبطاقة / الجواز ✅' : 'غير موثق (يرجى التوثيق) ⚠️',
                  ),
                  Divider(color: context.borderColor, height: 20),
                  _DetailRow(
                    icon: Icons.fingerprint_rounded,
                    label: 'معرف المستخدم (UID)',
                    value: user?.uid ?? 'sakani_user',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── 5. Quick Actions ──
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.accentColor,
                foregroundColor: const Color(0xFF080C14),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBr),
              ),
              onPressed: () => _showEditProfileDialog(user, auth),
              icon: const Icon(Icons.edit_rounded, size: 20),
              label: Text(
                'تعديل البيانات الشخصية',
                style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.accentColor),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.tajawal(
            color: context.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.tajawal(
              color: context.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
