import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/localization/app_localizations.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';
import 'package:sakani/core/widgets/app_text_field.dart';
import 'package:sakani/core/widgets/glass_card.dart';
import 'package:sakani/core/widgets/gradient_button.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_state.dart';
import 'package:sakani/features/auth/presentation/widgets/auth_background.dart';
import 'package:sakani/features/auth/presentation/widgets/auth_header.dart';
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

  void _fillDemo(String email, String pass) {
    _emailCtl.text = email;
    _passwordCtl.text = pass;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocaleProvider>().lang;
    final tr = AppLocalizations(lang);

    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            AppSnackbar.show(
              context,
              message: 'مرحباً بك، ${state.user.name.isNotEmpty ? state.user.name : "في سكني"}',
              type: ToastType.success,
            );
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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

          return AuthBackground(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTopBar(context, lang),
                      const SizedBox(height: 16),
                      AuthHeader(
                        title: tr.tr('appName'),
                        subtitle: tr.tr('appTagline'),
                      ),
                      const SizedBox(height: 32),

                      // Form Card
                      GlassCard(
                        borderRadius: AppRadius.xl,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr.tr('login'),
                              style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Email
                            AppTextField(
                              controller: _emailCtl,
                              label: tr.tr('email'),
                              hint: 'example@email.com',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icon(Icons.alternate_email_rounded, color: context.accentColor),
                              validator: (v) => (v != null && v.contains('@'))
                                  ? null
                                  : tr.tr('emailRequired'),
                            ),
                            const SizedBox(height: 16),

                            // Password
                            AppTextField(
                              controller: _passwordCtl,
                              label: tr.tr('password'),
                              hint: '••••••••',
                              obscureText: _obscurePassword,
                              prefixIcon: Icon(Icons.lock_outline_rounded, color: context.accentColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: context.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              validator: (v) => (v != null && v.length >= 6)
                                  ? null
                                  : tr.tr('passwordRequired'),
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            GradientButton(
                              text: tr.tr('login'),
                              isLoading: isLoading,
                              onPressed: isLoading ? null : _submitLogin,
                              icon: Icons.login_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Demo Quick Fill Chips
                      _buildDemoChips(context),
                      const SizedBox(height: 20),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tr.tr('noAccountText'),
                            style: TextStyle(color: context.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/register'),
                            child: Text(
                              tr.tr('register'),
                              style: TextStyle(
                                color: context.accentColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
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

  Widget _buildTopBar(BuildContext context, String lang) {
    return Align(
      alignment: lang == 'ar' ? Alignment.topLeft : Alignment.topRight,
      child: GestureDetector(
        onTap: () => context.read<LocaleProvider>().toggleLang(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: AppRadius.pillBr,
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.translate_rounded, size: 16, color: context.accentColor),
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
    );
  }

  Widget _buildDemoChips(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        ActionChip(
          label: const Text('تجربة مستأجر (Demo Tenant)'),
          avatar: const Icon(Icons.person_rounded, size: 16),
          onPressed: () => _fillDemo('tenant@sakani.com', '123456'),
        ),
        ActionChip(
          label: const Text('تجربة مالك (Demo Owner)'),
          avatar: const Icon(Icons.domain_rounded, size: 16),
          onPressed: () => _fillDemo('owner@sakani.com', '123456'),
        ),
      ],
    );
  }
}
