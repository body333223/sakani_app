import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/features/auth/data/services/auth_service.dart';
import 'package:sakani/features/auth/data/models/user_model.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  AppUser? get _user {
    final cubit = context.read<AuthCubit>();
    final auth = context.read<AuthProvider>();
    final entity = cubit.currentUser ?? auth.user ?? AuthService.currentUser;
    if (entity == null) return null;
    if (entity is AppUser) return entity;
    // Convert UserEntity to AppUser
    return AppUser(
      uid: entity.uid,
      email: entity.email,
      name: entity.name,
      phone: entity.phone,
      role: entity.role,
      photoUrl: entity.photoUrl,
      createdAt: entity.createdAt,
    );
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String _getRoleLabel(String role) =>
      role == 'owner' ? 'مالك عقار' : 'مستأجر';

  String _getRoleIcon(String role) => role == 'owner' ? '🏠' : '🔑';

  Color _getRoleColor(String role) =>
      role == 'owner' ? AppColors.gold : AppColors.info;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final user = _user;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF0F4F8),
      body: user == null
          ? _buildGuest()
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(user, isDark),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Column(
                            children: [
                              _buildStatsRow(user, isDark),
                              const SizedBox(height: 16),
                              _buildIdCard(user, isDark),
                              const SizedBox(height: 16),
                              _buildInfoCard(user, isDark),
                              const SizedBox(height: 16),
                              _buildActivityCard(user, isDark),
                              const SizedBox(height: 16),
                              _buildActionsCard(context, user, isDark),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildGuest() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 72, color: context.textSecondary),
          const SizedBox(height: 16),
          Text(
            'لم تقم بتسجيل الدخول',
            style: GoogleFonts.tajawal(fontSize: 18, color: context.textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: Text('تسجيل الدخول', style: GoogleFonts.tajawal(color: context.accentColor, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(AppUser user, bool isDark) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: context.textPrimary),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.edit_rounded, size: 16, color: context.accentColor),
          ),
          onPressed: () => _showEditSheet(user),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [Color(0xFF0D1322), Color(0xFF131B2F)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFFEF3C7), Color(0xFFF0F4F8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // Avatar
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: context.accentColor, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: context.accentColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: user.photoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _avatarPlaceholder(user),
                              errorWidget: (_, __, ___) => _avatarPlaceholder(user),
                            )
                          : _avatarPlaceholder(user),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: context.accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppColors.darkBg : Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                user.name.isNotEmpty ? user.name : 'مستخدم سكني',
                style: GoogleFonts.tajawal(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: _getRoleColor(user.role).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getRoleColor(user.role).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_getRoleIcon(user.role), style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    Text(
                      _getRoleLabel(user.role),
                      style: GoogleFonts.tajawal(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _getRoleColor(user.role),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.email,
                style: GoogleFonts.tajawal(fontSize: 12.5, color: context.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(AppUser user) {
    final initials = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'S';
    return Container(
      color: context.accentColor.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.tajawal(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: context.accentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(AppUser user, bool isDark) {
    return Row(
      children: [
        Expanded(child: _statCard(isDark, '0', 'إيجار مكتمل', Icons.home_work_rounded, AppColors.success)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(isDark, '0', 'تقييم مستلم', Icons.star_rounded, AppColors.gold)),
        const SizedBox(width: 10),
        Expanded(child: _statCard(isDark, '4.9', 'متوسط التقييم', Icons.verified_rounded, AppColors.info)),
      ],
    );
  }

  Widget _statCard(bool isDark, String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.tajawal(fontSize: 10, color: context.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIdCard(AppUser user, bool isDark) {
    // بطاقة الهوية الرقمية
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF1A2640), Color(0xFF0D1322)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFEF3C7), Color(0xFFF59E0B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.2),
            blurRadius: 20,
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
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.badge_rounded, color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'بطاقة الهوية الرقمية',
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.goldLight : Colors.brown[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.success, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      'موثق',
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _idRow('الاسم الكامل', user.name.isNotEmpty ? user.name : '—', isDark),
          const SizedBox(height: 10),
          _idRow('البريد الإلكتروني', user.email, isDark),
          const SizedBox(height: 10),
          _idRow('رقم الهاتف', user.phone.isNotEmpty ? user.phone : '—', isDark),
          const SizedBox(height: 10),
          _idRow('الدور', _getRoleLabel(user.role), isDark),
          const SizedBox(height: 10),
          _idRow('تاريخ الانضمام', _formatDate(user.createdAt), isDark),
        ],
      ),
    );
  }

  Widget _idRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 12,
              color: isDark ? AppColors.goldLight.withValues(alpha: 0.6) : Colors.brown[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.tajawal(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.brown[900],
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            AppSnackbar.show(context, message: 'تم النسخ', type: ToastType.success);
          },
          child: Icon(
            Icons.copy_rounded,
            size: 14,
            color: isDark ? AppColors.goldLight.withValues(alpha: 0.5) : Colors.brown[400],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(AppUser user, bool isDark) {
    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('معلومات الحساب', Icons.person_pin_rounded, isDark),
          const SizedBox(height: 14),
          _infoTile(isDark, Icons.alternate_email_rounded, 'معرف المستخدم', user.uid.length > 12 ? '${user.uid.substring(0, 12)}...' : user.uid, AppColors.info),
          _divider(isDark),
          _infoTile(isDark, Icons.security_rounded, 'حالة التوثيق', 'موثق بـ KYC', AppColors.success),
          _divider(isDark),
          _infoTile(isDark, Icons.lock_rounded, 'الأمان', 'حماية ثنائية', AppColors.gold),
        ],
      ),
    );
  }

  Widget _buildActivityCard(AppUser user, bool isDark) {
    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('النشاط والإحصائيات', Icons.bar_chart_rounded, isDark),
          const SizedBox(height: 14),
          _infoTile(isDark, Icons.home_rounded, 'إجمالي الإيجارات', '0 عملية', AppColors.success),
          _divider(isDark),
          _infoTile(isDark, Icons.star_half_rounded, 'متوسط التقييم', '4.9 / 5.0', AppColors.gold),
          _divider(isDark),
          _infoTile(isDark, Icons.thumb_up_rounded, 'معدل الموثوقية', '100%', AppColors.info),
          if (user.role == 'owner') ...[
            _divider(isDark),
            _infoTile(isDark, Icons.apartment_rounded, 'عقارات مدرجة', '0 عقار', AppColors.goldDark),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context, AppUser user, bool isDark) {
    return _card(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('الإجراءات السريعة', Icons.flash_on_rounded, isDark),
          const SizedBox(height: 14),
          _actionTile(
            isDark,
            Icons.verified_user_rounded,
            'تحقق الهوية (KYC)',
            'عرض وتحديث بيانات هويتك',
            AppColors.success,
            () => Navigator.pushNamed(context, '/kyc'),
          ),
          _divider(isDark),
          _actionTile(
            isDark,
            Icons.chat_bubble_rounded,
            'الدعم الفني',
            'تواصل مع فريق خدمة العملاء',
            AppColors.info,
            () => Navigator.pushNamed(context, '/support'),
          ),
          _divider(isDark),
          _actionTile(
            isDark,
            Icons.description_rounded,
            'عقودي الإلكترونية',
            'عرض كل العقود الرسمية',
            AppColors.gold,
            () {},
          ),
          _divider(isDark),
          _actionTile(
            isDark,
            Icons.settings_rounded,
            'إعدادات التطبيق',
            'التخصيص واللغة والمظهر',
            AppColors.textDarkSecondary,
            () => Navigator.pushNamed(context, '/settings'),
          ),
          _divider(isDark),
          _actionTile(
            isDark,
            Icons.logout_rounded,
            'تسجيل الخروج',
            'الخروج من الحساب بأمان',
            AppColors.error,
            () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _card(bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: context.accentColor, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.tajawal(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _infoTile(bool isDark, IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.tajawal(fontSize: 11, color: context.textSecondary),
                ),
                Text(
                  value,
                  style: GoogleFonts.tajawal(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(bool isDark, IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.tajawal(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: color == AppColors.error ? AppColors.error : context.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.tajawal(fontSize: 11, color: context.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_left_rounded, color: context.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      height: 1,
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  void _showEditSheet(AppUser user) {
    final nameCtl = TextEditingController(text: user.name);
    final phoneCtl = TextEditingController(text: user.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: context.isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'تعديل الملف الشخصي',
                style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w900, color: context.textPrimary),
              ),
              const SizedBox(height: 20),
              _editField(nameCtl, 'الاسم الكامل', Icons.person_rounded),
              const SizedBox(height: 14),
              _editField(phoneCtl, 'رقم الهاتف', Icons.phone_rounded, type: TextInputType.phone),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    await AuthService().updateProfile(user.uid, {
                      'name': nameCtl.text.trim(),
                      'phone': phoneCtl.text.trim(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      AppSnackbar.show(context, message: 'تم تحديث الملف الشخصي', type: ToastType.success);
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.accentColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('حفظ التعديلات', style: GoogleFonts.tajawal(fontWeight: FontWeight.w900, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField(TextEditingController ctl, String hint, IconData icon,
      {TextInputType? type}) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: TextField(
        controller: ctl,
        keyboardType: type,
        style: GoogleFonts.tajawal(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.tajawal(color: context.textSecondary),
          prefixIcon: Icon(icon, color: context.accentColor, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تأكيد الخروج', style: GoogleFonts.tajawal(fontWeight: FontWeight.w900, color: context.textPrimary)),
        content: Text('هل أنت متأكد من تسجيل الخروج من حسابك؟', style: GoogleFonts.tajawal(color: context.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.tajawal(color: context.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final authCubit = context.read<AuthCubit>();
              await authCubit.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('خروج', style: GoogleFonts.tajawal(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
