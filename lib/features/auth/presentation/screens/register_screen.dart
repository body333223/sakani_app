import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_state.dart';
import 'package:sakani/features/support/presentation/screens/support_chat_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  final _nationalIdCtl = TextEditingController();
  final _inviteCodeCtl = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'tenant';
  XFile? _selectedAvatar;
  int _currentStep = 0; // 0 = Info, 1 = Identity, 2 = Confirm
  bool _agreedToTerms = false;
  String? _idFrontPath;
  String? _idBackPath;

  static const _validInviteCodes = [
    'SAKANI-OWNER-2026',
    'SAKANI-VIP-ADMIN',
    'SAKANI-ROYAL',
    'ADMIN-PASS-2026',
    'SAKANI-DEV-77',
    'OWNER-VERIFIED',
  ];

  final ImagePicker _picker = ImagePicker();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _passwordCtl.dispose();
    _nationalIdCtl.dispose();
    _inviteCodeCtl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _selectedAvatar = img);
  }

  Future<void> _pickIdImage(bool isFront) async {
    final img = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (img != null) {
      setState(() {
        if (isFront) {
          _idFrontPath = img.path;
        } else {
          _idBackPath = img.path;
        }
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
      _animCtrl.reset();
      setState(() => _currentStep = 1);
      _animCtrl.forward();
    } else if (_currentStep == 1) {
      final nid = _nationalIdCtl.text.trim();
      if (nid.length != 14 || !RegExp(r'^[23]\d{13}$').hasMatch(nid)) {
        AppSnackbar.show(
          context,
          message: 'يرجى إدخال رقم قومي مصري صحيح مكون من 14 رقم يبدأ بـ 2 أو 3',
          type: ToastType.error,
        );
        return;
      }
      if (_idFrontPath == null || _idBackPath == null) {
        AppSnackbar.show(
          context,
          message: 'توثيق الهوية إلزامي: يرجى تصوير وجه وظهر بطاقة الرقم القومي',
          type: ToastType.error,
        );
        return;
      }
      _animCtrl.reset();
      setState(() => _currentStep = 2);
      _animCtrl.forward();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _animCtrl.reset();
      setState(() => _currentStep--);
      _animCtrl.forward();
    }
  }

  void _submitRegister() {
    if (!_agreedToTerms) {
      AppSnackbar.show(context, message: 'يجب الموافقة على الشروط والأحكام أولاً', type: ToastType.error);
      return;
    }

    final code = _inviteCodeCtl.text.trim().toUpperCase();
    final isOwner = _selectedRole == 'owner';
    final hasValidInvite = code.isNotEmpty && _validInviteCodes.contains(code);
    final isApproved = !isOwner || hasValidInvite;

    context.read<AuthCubit>().register(
          email: _emailCtl.text.trim(),
          password: _passwordCtl.text,
          name: _nameCtl.text.trim(),
          phone: _phoneCtl.text.trim(),
          role: _selectedRole,
          photoUrl: _selectedAvatar?.path,
          nationalId: _nationalIdCtl.text.trim(),
          idFrontPath: _idFrontPath,
          idBackPath: _idBackPath,
          inviteCode: code.isNotEmpty ? code : null,
          isApproved: isApproved,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: context.textPrimary),
          ),
          onPressed: _currentStep > 0 ? _prevStep : () => Navigator.pop(context),
        ),
        title: Text(
          'إنشاء حساب جديد',
          style: GoogleFonts.tajawal(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportChatScreen()),
              );
            },
            icon: const Icon(Icons.support_agent_rounded, size: 18),
            label: Text(
              'الدعم',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            style: TextButton.styleFrom(foregroundColor: context.accentColor),
          ),
        ],
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            if (state.user.isOwner) {
              if (state.user.isOwnerPendingApproval) {
                AppSnackbar.show(
                  context,
                  message: 'تم إرسال طلب حساب المالك لمراجعة الإدارة بنجاح',
                  type: ToastType.info,
                );
                Navigator.pushNamedAndRemoveUntil(context, '/owner-pending', (route) => false);
              } else {
                AppSnackbar.show(
                  context,
                  message: 'مرحباً بك يا شريكنا! تم تفعيل حساب المالك بنجاح 🎉',
                  type: ToastType.success,
                );
                Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
              }
            } else {
              AppSnackbar.show(
                context,
                message: 'مرحباً بك في سكني! تم توثيق هويتك وإنشاء حسابك بنجاح 🎉',
                type: ToastType.success,
              );
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            }
          } else if (state is AuthError) {
            AppSnackbar.show(context, message: state.message, type: ToastType.error);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SafeArea(
            child: Column(
              children: [
                // Progress Indicator
                _buildProgressBar(isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildCurrentStep(isDark, isLoading),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final steps = ['بياناتك', 'الهوية KYC', 'التأكيد'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                // Circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppColors.success
                        : isActive
                            ? context.accentColor
                            : isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                    shape: BoxShape.circle,
                    boxShadow: isActive
                        ? [BoxShadow(color: context.accentColor.withValues(alpha: 0.4), blurRadius: 8)]
                        : null,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                        : Text(
                            '${i + 1}',
                            style: GoogleFonts.tajawal(
                              color: isActive ? Colors.black : context.textSecondary,
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  steps[i],
                  style: GoogleFonts.tajawal(
                    fontSize: 11,
                    fontWeight: isActive || isDone ? FontWeight.w800 : FontWeight.w600,
                    color: isActive ? context.accentColor : (isDone ? AppColors.success : context.textSecondary),
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.success
                            : isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(bool isDark, bool isLoading) {
    switch (_currentStep) {
      case 0:
        return _buildStep1(isDark, isLoading);
      case 1:
        return _buildStep2(isDark);
      case 2:
        return _buildStep3(isDark, isLoading);
      default:
        return const SizedBox();
    }
  }

  /// Step 1: Basic Info & Role
  Widget _buildStep1(bool isDark, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أولاً، بيانات الحساب الأساسية',
          style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w900, color: context.textPrimary),
        ),
        Text(
          'اختر نوع الحساب وأدخل بياناتك لإنشاء الحساب',
          style: GoogleFonts.tajawal(fontSize: 13, color: context.textSecondary),
        ),
        const SizedBox(height: 20),

        // Avatar
        Center(
          child: GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkCard : Colors.white,
                    border: Border.all(color: context.accentColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(color: context.accentColor.withValues(alpha: 0.25), blurRadius: 16),
                    ],
                  ),
                  child: ClipOval(
                    child: _selectedAvatar != null
                        ? Image.file(File(_selectedAvatar!.path), fit: BoxFit.cover)
                        : Icon(Icons.person_rounded, size: 44, color: context.accentColor),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: context.accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppColors.darkBg : Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text('صورة شخصية (اختياري)', style: GoogleFonts.tajawal(fontSize: 11.5, color: context.textSecondary)),
        ),
        const SizedBox(height: 18),

        // Role Selector
        Row(
          children: [
            Expanded(child: _roleCard('tenant', 'مستأجر عقار', Icons.key_rounded, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _roleCard('owner', 'مالك عقار / تاجر', Icons.home_work_rounded, isDark)),
          ],
        ),
        const SizedBox(height: 16),

        // Owner Notice & Invite Code option
        if (_selectedRole == 'owner')
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [Colors.white, const Color(0xFFFEF3C7).withValues(alpha: 0.4)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Color(0xFFD97706), size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سياسة اعتماد حساب المالك',
                        style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFFD97706)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'لحماية المستأجرين وضمان حقوق الملاك، لا يتم تفعيل حساب المالك تلقائياً إلا بعد موافقة الإدارة أو إدخال كود دعوة معتمد.',
                  style: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'كود دعوة الإدارة (اختياري للتفعيل الفوري):',
                  style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w700, color: context.textPrimary),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: TextField(
                    controller: _inviteCodeCtl,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, letterSpacing: 1.5, color: context.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'مثال: SAKANI-OWNER-2026',
                      hintStyle: GoogleFonts.tajawal(color: context.textSecondary.withValues(alpha: 0.4), letterSpacing: 0, fontSize: 12),
                      prefixIcon: const Icon(Icons.vpn_key_rounded, size: 18, color: Color(0xFFD97706)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Form
        Form(
          key: _formKey,
          child: _buildFormCard(isDark),
        ),
        const SizedBox(height: 18),
        _buildNextButton('التالي: توثيق الهوية (إلزامي)', Icons.arrow_forward_rounded, _nextStep),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('لديك حساب بالفعل؟', style: GoogleFonts.tajawal(color: context.textSecondary, fontSize: 13)),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('تسجيل الدخول', style: GoogleFonts.tajawal(color: context.accentColor, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ],
    );
  }

  /// Step 2: Mandatory Identity Verification (KYC)
  Widget _buildStep2(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.verified_user_rounded, color: context.accentColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'توثيق الهوية الوطنية (KYC الإلزامي)',
                    style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.w900, color: context.textPrimary),
                  ),
                  Text(
                    'شرط أساسي لإنشاء الحساب وتوثيق العقود الإلكترونية',
                    style: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Security assurance banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'بيانات الرقم القومي وصور الهوية يتم تشفيرها ببصمة SHA-256 لحماية حسابك ولن يتم استخدامها إلا في توليد عقود الإيجار الرسمية الموثقة.',
                  style: GoogleFonts.tajawal(fontSize: 11.5, color: context.textSecondary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // National ID number
        _sectionLabel('الرقم القومي (14 رقم - إلزامي)', isDark),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _nationalIdCtl.text.length == 14 ? AppColors.success : context.borderColor,
            ),
          ),
          child: TextField(
            controller: _nationalIdCtl,
            keyboardType: TextInputType.number,
            maxLength: 14,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.tajawal(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2),
            decoration: InputDecoration(
              hintText: '29XXXXXXXXXXXX',
              hintStyle: GoogleFonts.tajawal(color: context.textSecondary.withValues(alpha: 0.4), letterSpacing: 0, fontSize: 13),
              prefixIcon: Icon(Icons.credit_card_rounded, color: context.accentColor, size: 20),
              suffixIcon: _nationalIdCtl.text.length == 14
                  ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20)
                  : null,
              border: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // ID Front Photo
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel('صورة وجه بطاقة الرقم القومي (إلزامي)', isDark),
            if (_idFrontPath != null)
              Text('تم الرفع ✓', style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success)),
          ],
        ),
        const SizedBox(height: 6),
        _idPhotoBox(true, isDark),
        const SizedBox(height: 16),

        // ID Back Photo
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionLabel('صورة ظهر بطاقة الرقم القومي (إلزامي)', isDark),
            if (_idBackPath != null)
              Text('تم الرفع ✓', style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.success)),
          ],
        ),
        const SizedBox(height: 6),
        _idPhotoBox(false, isDark),
        const SizedBox(height: 24),

        _buildNextButton('التالي: مراجعة وتأكيد البيانات', Icons.arrow_forward_rounded, _nextStep),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _idPhotoBox(bool isFront, bool isDark) {
    final path = isFront ? _idFrontPath : _idBackPath;
    return GestureDetector(
      onTap: () => _pickIdImage(isFront),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 135,
        decoration: BoxDecoration(
          color: path != null
              ? AppColors.success.withValues(alpha: 0.06)
              : isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: path != null ? AppColors.success : context.borderColor,
            width: path != null ? 1.8 : 1,
          ),
        ),
        child: path != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(path), fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text('تم التقاط الهوية', style: GoogleFonts.tajawal(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFront ? Icons.badge_outlined : Icons.flip_rounded,
                    color: context.accentColor,
                    size: 34,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFront ? 'التقط صورة واضحة لوجه البطاقة' : 'التقط صورة واضحة لظهر البطاقة',
                    style: GoogleFonts.tajawal(fontSize: 13.5, fontWeight: FontWeight.w800, color: context.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'اضغط لفتح الكاميرا والتقاط البطاقة',
                    style: GoogleFonts.tajawal(fontSize: 11, color: context.textSecondary),
                  ),
                ],
              ),
      ),
    );
  }

  /// Step 3: Review & Submit
  Widget _buildStep3(bool isDark, bool isLoading) {
    final code = _inviteCodeCtl.text.trim().toUpperCase();
    final isOwner = _selectedRole == 'owner';
    final hasValidInvite = code.isNotEmpty && _validInviteCodes.contains(code);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ثالثاً، مراجعة وتأكيد الحساب',
          style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w900, color: context.textPrimary),
        ),
        Text(
          'تأكد من صحة بياناتك قبل إتمام إنشاء الحساب',
          style: GoogleFonts.tajawal(fontSize: 13, color: context.textSecondary),
        ),
        const SizedBox(height: 18),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 12)],
          ),
          child: Column(
            children: [
              _summaryRow(isDark, Icons.person_rounded, 'الاسم بالكامل', _nameCtl.text, context.accentColor),
              _divider(isDark),
              _summaryRow(isDark, Icons.email_rounded, 'البريد الإلكتروني', _emailCtl.text, AppColors.info),
              _divider(isDark),
              _summaryRow(isDark, Icons.phone_rounded, 'الهاتف', _phoneCtl.text, AppColors.success),
              _divider(isDark),
              _summaryRow(isDark, Icons.credit_card_rounded, 'الرقم القومي', '••••••••${_nationalIdCtl.text.substring(_nationalIdCtl.text.length - 4)}', context.accentColor),
              _divider(isDark),
              _summaryRow(
                isDark,
                isOwner ? Icons.home_work_rounded : Icons.key_rounded,
                'نوع الحساب',
                isOwner ? 'مالك عقار' : 'مستأجر',
                isOwner ? const Color(0xFFF59E0B) : AppColors.info,
              ),
              _divider(isDark),
              // KYC Status
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('توثيق الهوية (KYC)', style: GoogleFonts.tajawal(fontSize: 11, color: context.textSecondary)),
                          Text('مكتمل وموثق ✓', style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.success)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Approval Notice for Owner
        if (isOwner)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasValidInvite
                  ? AppColors.success.withValues(alpha: 0.1)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasValidInvite
                    ? AppColors.success.withValues(alpha: 0.4)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasValidInvite ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                      color: hasValidInvite ? AppColors.success : const Color(0xFFD97706),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasValidInvite ? 'كود دعوة معتمد - تفعيل فوري' : 'الحساب يتطلب اعتماد الإدارة',
                        style: GoogleFonts.tajawal(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: hasValidInvite ? AppColors.success : const Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  hasValidInvite
                      ? 'تم التحقق من كود الدعوة المعتمد ($code). سيتم تفعيل حساب المالك فوراً.'
                      : 'سيتم تقديم طلب الحساب للمراجعة من قِبل إدارة سكني. لن يتمكن الحساب من الوصول للداشبورد حتى يتم الاعتماد أو إدخال كود دعوة.',
                  style: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Terms Agreement
        GestureDetector(
          onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _agreedToTerms ? context.accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _agreedToTerms ? context.accentColor : context.borderColor, width: 1.5),
                ),
                child: _agreedToTerms ? const Icon(Icons.check_rounded, color: Colors.black, size: 14) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.tajawal(fontSize: 12.5, color: context.textSecondary),
                    children: [
                      const TextSpan(text: 'أوافق على '),
                      TextSpan(
                        text: 'الشروط والأحكام',
                        style: TextStyle(color: context.accentColor, fontWeight: FontWeight.w800),
                      ),
                      const TextSpan(text: ' وسياسة توثيق العقود وحماية الخصوصية'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading ? null : _submitRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.accentColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.rocket_launch_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isOwner && !hasValidInvite ? 'إرسال طلب الحساب للاعتماد' : 'إنشاء وتفعيل الحساب الآن',
                        style: GoogleFonts.tajawal(fontSize: 15.5, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _summaryRow(bool isDark, IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.tajawal(fontSize: 11, color: context.textSecondary)),
                Text(value, style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w800, color: context.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(String label, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: GoogleFonts.tajawal(fontSize: 15, fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.accentColor,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _roleCard(String role, String label, IconData icon, bool isDark) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? context.accentColor.withValues(alpha: 0.12) : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? context.accentColor : context.borderColor,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: context.accentColor.withValues(alpha: 0.2), blurRadius: 10)]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: isSelected ? context.accentColor : context.textSecondary),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.tajawal(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? context.accentColor : context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('الاسم بالكامل', isDark),
          const SizedBox(height: 6),
          _inputField(
            controller: _nameCtl,
            hint: 'مثال: محمد أحمد',
            icon: Icons.person_rounded,
            isDark: isDark,
            validator: (v) => (v != null && v.trim().length >= 3) ? null : 'يرجى إدخال اسم لا يقل عن 3 أحرف',
          ),
          const SizedBox(height: 14),
          _sectionLabel('البريد الإلكتروني', isDark),
          const SizedBox(height: 6),
          _inputField(
            controller: _emailCtl,
            hint: 'example@email.com',
            icon: Icons.alternate_email_rounded,
            isDark: isDark,
            type: TextInputType.emailAddress,
            validator: (v) => (v != null && v.contains('@') && v.contains('.')) ? null : 'يرجى إدخال بريد إلكتروني صحيح',
          ),
          const SizedBox(height: 14),
          _sectionLabel('رقم الهاتف المحمول', isDark),
          const SizedBox(height: 6),
          _inputField(
            controller: _phoneCtl,
            hint: '01XXXXXXXXX',
            icon: Icons.phone_android_rounded,
            isDark: isDark,
            type: TextInputType.phone,
            validator: (v) => (v != null && RegExp(r'^01[0125]\d{8}$').hasMatch(v.trim())) ? null : 'يرجى إدخال رقم هاتف مصري صحيح (11 رقم)',
          ),
          const SizedBox(height: 14),
          _sectionLabel('كلمة المرور', isDark),
          const SizedBox(height: 6),
          _inputField(
            controller: _passwordCtl,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            isDark: isDark,
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: context.textSecondary,
                size: 19,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) => (v != null && v.length >= 6) ? null : 'كلمة المرور يجب أن لا تقل عن 6 أحرف',
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: GoogleFonts.tajawal(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.textPrimary),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? type,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        validator: validator,
        style: GoogleFonts.tajawal(color: context.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.tajawal(color: context.textSecondary.withValues(alpha: 0.4), fontSize: 13),
          prefixIcon: Icon(icon, color: context.accentColor, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _divider(bool isDark) {
    return Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 1);
  }
}
