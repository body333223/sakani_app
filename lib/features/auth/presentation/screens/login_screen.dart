import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/services/biometric_service.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';
import 'package:sakani/core/widgets/staggered_entrance.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_state.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isBiometricSupported = false;

  @override
  void initState() {
    super.initState();
    _initBiometricsAndRememberMe();
  }

  Future<void> _initBiometricsAndRememberMe() async {
    final isRemember = BiometricService.isRememberMeEnabled();
    final saved = BiometricService.getSavedCredentials();
    final supported = await BiometricService.isBiometricsSupported();

    if (mounted) {
      setState(() {
        _rememberMe = isRemember;
        _isBiometricSupported = supported;
        if (saved != null && isRemember) {
          _emailCtl.text = saved['email'] ?? '';
          _passwordCtl.text = saved['password'] ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
          _emailCtl.text.trim(),
          _passwordCtl.text,
        );
  }

  Future<void> _loginWithBiometrics() async {
    final saved = BiometricService.getSavedCredentials();
    if (saved == null) {
      AppSnackbar.show(
        context,
        message: 'يرجى تسجيل الدخول يدوياً أولاً مع تفعيل خيار "تذكرني" لحفظ البصمة',
        type: ToastType.warning,
      );
      return;
    }

    final authenticated = await BiometricService.authenticate(
      reason: 'يرجى استخدام بصمة الإصبع أو Face ID لتسجيل الدخول السريع',
    );

    if (authenticated && mounted) {
      _emailCtl.text = saved['email']!;
      _passwordCtl.text = saved['password']!;
      AppSnackbar.show(
        context,
        message: 'تم التحقق من البصمة بنجاح! جاري تسجيل الدخول... 🌟',
        type: ToastType.success,
      );
      context.read<AuthCubit>().login(saved['email']!, saved['password']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().lang;
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF080C14) : const Color(0xFFF8FAFC),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            if (_rememberMe) {
              BiometricService.saveCredentials(
                email: _emailCtl.text.trim(),
                password: _passwordCtl.text,
              );
            } else {
              BiometricService.clearSavedCredentials();
            }
            AppSnackbar.show(
              context,
              message: 'مرحباً بك، ${state.user.name.isNotEmpty ? state.user.name : "في سكني"}',
              type: ToastType.success,
            );
            if (state.user.isOwner) {
              if (state.user.isOwnerPendingApproval) {
                Navigator.pushNamedAndRemoveUntil(context, '/owner-pending', (route) => false);
              } else {
                Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
              }
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            }
          } else if (state is AuthError) {
            AppSnackbar.show(
              context,
              message: state.message,
              type: ToastType.error,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Top Bar with Language switcher
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.shield_outlined, size: 14, color: context.accentColor),
                                const SizedBox(width: 4),
                                Text(
                                  'منصة آمنة وموثقة',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: context.accentColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          BouncingTap(
                            onTap: () => context.read<LocaleProvider>().toggleLang(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.borderColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.translate_rounded, size: 14, color: context.accentColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    lang == 'ar' ? 'English' : 'العربية',
                                    style: TextStyle(
                                      color: context.accentColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Logo & Welcome Header
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: context.accentColor.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/images/app_logo.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: context.accentColor,
                              child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 40),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'مرحباً بك مجدداً',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'سجل الدخول للمتابعة واستكشاف أفضل الشقق',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Login Form Card ──
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : context.borderColor,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email Field
                            _buildInputLabel('البريد الإلكتروني'),
                            const SizedBox(height: 6),
                            _buildInputField(
                              controller: _emailCtl,
                              hint: 'name@example.com',
                              prefixIcon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => (v != null && v.contains('@'))
                                  ? null
                                  : 'يرجى إدخال بريد إلكتروني صحيح',
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            _buildInputLabel('كلمة المرور'),
                            const SizedBox(height: 6),
                            _buildInputField(
                              controller: _passwordCtl,
                              hint: '••••••••',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: context.textSecondary,
                                  size: 19,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) => (v != null && v.length >= 6)
                                  ? null
                                  : 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                            ),
                            const SizedBox(height: 14),

                            // ── Remember Me ("تذكرني") Option ──
                            Row(
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: context.accentColor,
                                    checkColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    onChanged: (val) {
                                      setState(() => _rememberMe = val ?? false);
                                      BiometricService.setRememberMe(_rememberMe);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _rememberMe = !_rememberMe);
                                    BiometricService.setRememberMe(_rememberMe);
                                  },
                                  child: Text(
                                    'تذكر بيانات الدخول',
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Submit Button
                            BouncingTap(
                              scaleFactor: 0.97,
                              onTap: isLoading ? null : _submitLogin,
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [context.accentColor, AppColors.goldDark],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.accentColor.withValues(alpha: 0.38),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.login_rounded, color: Colors.black, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'تسجيل الدخول',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),

                            // ── Biometric Fingerprint Button ──
                            if (_isBiometricSupported) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: context.borderColor)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      'أو الدخول السريع',
                                      style: TextStyle(
                                        color: context.textSecondary.withValues(alpha: 0.7),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: context.borderColor)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              BouncingTap(
                                scaleFactor: 0.97,
                                onTap: isLoading ? null : _loginWithBiometrics,
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: context.cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: context.accentColor.withValues(alpha: 0.45),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: context.accentColor.withValues(alpha: 0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.fingerprint_rounded,
                                        color: context.accentColor,
                                        size: 26,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'تسجيل الدخول بالبصمة / Face ID',
                                        style: TextStyle(
                                          color: context.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ليس لديك حساب بعد؟',
                            style: TextStyle(color: context.textSecondary, fontSize: 13.5),
                          ),
                          const SizedBox(width: 6),
                          BouncingTap(
                            onTap: () => Navigator.pushNamed(context, '/register'),
                            child: Text(
                              'إنشاء حساب جديد',
                              style: TextStyle(
                                color: context.accentColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: context.textPrimary,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(
        color: context.textPrimary,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: context.textSecondary.withValues(alpha: 0.6),
          fontSize: 13.5,
        ),
        prefixIcon: Icon(prefixIcon, color: context.accentColor, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: context.isDark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: context.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: context.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: context.accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
