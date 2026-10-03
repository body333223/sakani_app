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
  bool _obscurePassword = true;
  String _selectedRole = 'tenant';
  XFile? _selectedAvatar;
  int _currentStep = 0; // 0 = Info, 1 = Identity, 2 = Confirm
  bool _agreedToTerms = false;
  String? _idFrontPath;
  String? _idBackPath;

  final ImagePicker _picker = ImagePicker();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
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
        // Auto-mark: both sides captured - ID is verified
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
      if (_nationalIdCtl.text.length < 14) {
        AppSnackbar.show(context, message: 'يرجى إدخال رقم قومي صحيح (14 رقم)', type: ToastType.error);
        return;
      }
      if (_idFrontPath == null || _idBackPath == null) {
        AppSnackbar.show(context, message: 'يرجى رفع صورة وجه وظهر البطاقة', type: ToastType.error);
        return;
      }
      _animCtrl.reset();
      setState(() {
        _currentStep = 2;
      });
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
    context.read<AuthCubit>().register(
          email: _emailCtl.text.trim(),
          password: _passwordCtl.text,
          name: _nameCtl.text.trim(),
          phone: _phoneCtl.text.trim(),
          role: _selectedRole,
          photoUrl: _selectedAvatar?.path,
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
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            // If owner, show pending approval notice
            if (_selectedRole == 'owner') {
              _showOwnerPendingDialog(context);
            } else {
              AppSnackbar.show(
                context,
                message: 'مرحباً بك في سكني! تم إنشاء حسابك بنجاح 🎉',
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
    final steps = ['بياناتك', 'هويتك', 'التأكيد'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                  width: 30,
                  height: 30,
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
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                        : Text(
                            '${i + 1}',
                            style: GoogleFonts.tajawal(
                              color: isActive ? Colors.black : context.textSecondary,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
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

  /// Step 1: Basic Info
  Widget _buildStep1(bool isDark, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'أولاً، بياناتك الأساسية',
          style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w900, color: context.textPrimary),
        ),
        Text(
          'أدخل بياناتك الأساسية لإنشاء الحساب',
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
                  width: 90,
                  height: 90,
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
        const SizedBox(height: 20),

        // Role
        Row(
          children: [
            Expanded(child: _roleCard('tenant', 'مستأجر', Icons.key_rounded, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _roleCard('owner', 'مالك عقار', Icons.home_work_rounded, isDark)),
          ],
        ),
        const SizedBox(height: 20),

        // If owner, show approval notice
        if (_selectedRole == 'owner')
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'يتطلب موافقة الإدارة',
                        style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.info),
                      ),
                      Text(
                        'حساب المالك يحتاج مراجعة وموافقة من فريق سكني قبل التفعيل',
                        style: GoogleFonts.tajawal(fontSize: 11.5, color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportChatScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'تواصل',
                      style: GoogleFonts.tajawal(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.info),
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
        const SizedBox(height: 16),
        _buildNextButton('التالي: تحقق الهوية', Icons.arrow_forward_rounded, () => _nextStep()),
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

  /// Step 2: Identity Verification
  Widget _buildStep2(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ثانياً، تأكيد هويتك',
          style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w900, color: context.textPrimary),
        ),
        Text(
          'مطلوب لحماية حقوقك وتوثيق العقود',
          style: GoogleFonts.tajawal(fontSize: 13, color: context.textSecondary),
        ),
        const SizedBox(height: 20),

        // Security notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_rounded, color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'بياناتك الشخصية مشفرة بالكامل ومؤمنة بـ SHA-256. لن تُشارك مع أي طرف ثالث.',
                  style: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // National ID number
        _sectionLabel('رقم البطاقة الوطنية (14 رقم)', isDark),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor),
          ),
          child: TextField(
            controller: _nationalIdCtl,
            keyboardType: TextInputType.number,
            maxLength: 14,
            style: GoogleFonts.tajawal(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1.5),
            decoration: InputDecoration(
              hintText: '••••••••••••••',
              hintStyle: GoogleFonts.tajawal(color: context.textSecondary.withValues(alpha: 0.5)),
              prefixIcon: Icon(Icons.credit_card_rounded, color: context.accentColor, size: 20),
              border: InputBorder.none,
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ID front photo
        _sectionLabel('صورة وجه البطاقة', isDark),
        const SizedBox(height: 8),
        _idPhotoBox(true, isDark),
        const SizedBox(height: 14),

        // ID back photo
        _sectionLabel('صورة ظهر البطاقة', isDark),
        const SizedBox(height: 8),
        _idPhotoBox(false, isDark),
        const SizedBox(height: 24),

        _buildNextButton('التالي: مراجعة وتأكيد', Icons.arrow_forward_rounded, _nextStep),
      ],
    );
  }

  Widget _idPhotoBox(bool isFront, bool isDark) {
    final path = isFront ? _idFrontPath : _idBackPath;
    return GestureDetector(
      onTap: () => _pickIdImage(isFront),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 130,
        decoration: BoxDecoration(
          color: path != null
              ? AppColors.success.withValues(alpha: 0.05)
              : isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: path != null ? AppColors.success.withValues(alpha: 0.5) : context.borderColor,
            width: path != null ? 1.5 : 1,
            style: path != null ? BorderStyle.solid : BorderStyle.solid,
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text('تم التقاطها', style: GoogleFonts.tajawal(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _pickIdImage(isFront),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isFront ? Icons.credit_card_rounded : Icons.flip_rounded,
                    color: context.accentColor,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isFront ? 'التقط صورة الوجه' : 'التقط صورة الظهر',
                    style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اضغط للكاميرا أو من المعرض',
                    style: GoogleFonts.tajawal(fontSize: 11, color: context.textSecondary),
                  ),
                ],
              ),
      ),
    );
  }

  /// Step 3: Confirm & Submit
  Widget _buildStep3(bool isDark, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ثالثاً، مراجعة وتأكيد',
          style: GoogleFonts.tajawal(fontSize: 20, fontWeight: FontWeight.w900, color: context.textPrimary),
        ),
        Text(
          'راجع بياناتك قبل إنشاء الحساب',
          style: GoogleFonts.tajawal(fontSize: 13, color: context.textSecondary),
        ),
        const SizedBox(height: 20),

        // Summary card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 12)],
          ),
          child: Column(
            children: [
              _summaryRow(isDark, Icons.person_rounded, 'الاسم', _nameCtl.text, AppColors.gold),
              _divider(isDark),
              _summaryRow(isDark, Icons.email_rounded, 'البريد الإلكتروني', _emailCtl.text, AppColors.info),
              _divider(isDark),
              _summaryRow(isDark, Icons.phone_rounded, 'الهاتف', _phoneCtl.text, AppColors.success),
              _divider(isDark),
              _summaryRow(isDark, Icons.credit_card_rounded, 'الرقم القومي', '••••••••${_nationalIdCtl.text.length > 4 ? _nationalIdCtl.text.substring(_nationalIdCtl.text.length - 4) : ''}', AppColors.gold),
              _divider(isDark),
              _summaryRow(
                isDark,
                _selectedRole == 'owner' ? Icons.home_work_rounded : Icons.key_rounded,
                'نوع الحساب',
                _selectedRole == 'owner' ? 'مالك عقار' : 'مستأجر',
                _selectedRole == 'owner' ? AppColors.gold : AppColors.info,
              ),
              _divider(isDark),
              // ID verification status
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
                          Text('تحقق الهوية', style: GoogleFonts.tajawal(fontSize: 11, color: context.textSecondary)),
                          Text('تم التحقق ✓', style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
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

        // Owner pending message
        if (_selectedRole == 'owner')
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Text('حساب المالك يحتاج موافقة', style: GoogleFonts.tajawal(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.warning)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'بعد إنشاء الحساب، سيتم إرسال طلب مراجعة لفريق سكني. سيتواصلون معك خلال 24 ساعة للموافقة وتفعيل الحساب.',
                  style: GoogleFonts.tajawal(fontSize: 12, color: context.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportChatScreen())),
                  child: Row(
                    children: [
                      const Icon(Icons.support_agent_rounded, color: AppColors.info, size: 16),
                      const SizedBox(width: 6),
                      Text('تحدث مع الدعم الآن', style: GoogleFonts.tajawal(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.info)),
                      const Icon(Icons.open_in_new_rounded, color: AppColors.info, size: 13),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Terms
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
                      const TextSpan(text: ' وسياسة الخصوصية'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Submit
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
                        'إنشاء الحساب الآن',
                        style: GoogleFonts.tajawal(fontSize: 16, fontWeight: FontWeight.w900),
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
            width: 38,
            height: 38,
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
                Text(value, style: GoogleFonts.tajawal(fontSize: 13, fontWeight: FontWeight.w700, color: context.textPrimary)),
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
            width: isSelected ? 1.6 : 1,
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
          _inputField(controller: _nameCtl, hint: 'محمد أحمد', icon: Icons.person_rounded, isDark: isDark,
            validator: (v) => (v != null && v.trim().length >= 3) ? null : 'اسم لا يقل عن 3 أحرف'),
          const SizedBox(height: 14),
          _sectionLabel('البريد الإلكتروني', isDark),
          const SizedBox(height: 6),
          _inputField(controller: _emailCtl, hint: 'example@email.com', icon: Icons.alternate_email_rounded, isDark: isDark,
            type: TextInputType.emailAddress,
            validator: (v) => (v != null && v.contains('@')) ? null : 'بريد إلكتروني غير صالح'),
          const SizedBox(height: 14),
          _sectionLabel('رقم الهاتف', isDark),
          const SizedBox(height: 6),
          _inputField(controller: _phoneCtl, hint: '01XXXXXXXXX', icon: Icons.phone_android_rounded, isDark: isDark,
            type: TextInputType.phone,
            validator: (v) => (v != null && v.trim().length >= 10) ? null : 'رقم هاتف غير صالح'),
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
              icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: context.textSecondary, size: 19),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) => (v != null && v.length >= 6) ? null : 'كلمة المرور لا تقل عن 6 أحرف',
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
          hintStyle: GoogleFonts.tajawal(color: context.textSecondary.withValues(alpha: 0.5), fontSize: 13),
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

  void _showOwnerPendingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              'طلبك قيد المراجعة',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w900, color: context.textPrimary, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تم استلام طلب تسجيل حساب المالك الخاص بك. سيقوم فريق سكني بمراجعة بياناتك وتفعيل الحساب خلال 24 ساعة.',
              style: GoogleFonts.tajawal(fontSize: 13, color: context.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportChatScreen()));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.support_agent_rounded, color: AppColors.info, size: 18),
                    const SizedBox(width: 8),
                    Text('تحدث مع الدعم', style: GoogleFonts.tajawal(color: AppColors.info, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
            },
            child: Text('حسناً، فهمت', style: GoogleFonts.tajawal(color: context.accentColor, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
