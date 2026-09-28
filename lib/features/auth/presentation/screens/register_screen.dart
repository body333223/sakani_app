import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sakani/core/config/theme.dart';
import 'package:sakani/core/localization/app_localizations.dart';
import 'package:sakani/core/widgets/app_snackbar.dart';
import 'package:sakani/core/widgets/app_text_field.dart';
import 'package:sakani/core/widgets/glass_card.dart';
import 'package:sakani/core/widgets/gradient_button.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:sakani/features/auth/presentation/cubit/auth_state.dart';
import 'package:sakani/features/auth/presentation/widgets/auth_background.dart';
import 'package:sakani/features/auth/presentation/widgets/avatar_picker_widget.dart';
import 'package:sakani/features/auth/presentation/widgets/role_selector_tab.dart';
import 'package:sakani/features/settings/presentation/providers/locale_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'tenant';
  XFile? _selectedAvatar;

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  void _submitRegister() {
    if (!_formKey.currentState!.validate()) return;
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
    final lang = context.watch<LocaleProvider>().lang;
    final tr = AppLocalizations(lang);

    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            AppSnackbar.show(
              context,
              message: 'تم إنشاء الحساب بنجاح، أهلاً بك!',
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
                    children: [
                      // Header & Back Button
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                            color: context.textPrimary,
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Spacer(),
                          Text(
                            tr.tr('register'),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48), // Balance spacing
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Avatar Picker
                      AvatarPickerWidget(
                        imageFile: _selectedAvatar,
                        onImageSelected: (file) => setState(() => _selectedAvatar = file),
                      ),
                      const SizedBox(height: 24),

                      // Role Selector
                      RoleSelectorTab(
                        selectedRole: _selectedRole,
                        onRoleChanged: (role) => setState(() => _selectedRole = role),
                      ),
                      const SizedBox(height: 20),

                      // Form Container
                      GlassCard(
                        borderRadius: AppRadius.xl,
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            // Full Name
                            AppTextField(
                              controller: _nameCtl,
                              label: tr.tr('fullName'),
                              hint: 'أحمد محمد',
                              prefixIcon: Icon(Icons.person_outline_rounded, color: context.accentColor),
                              validator: (v) => (v != null && v.trim().length >= 3)
                                  ? null
                                  : tr.tr('nameRequired'),
                            ),
                            const SizedBox(height: 14),

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
                            const SizedBox(height: 14),

                            // Phone
                            AppTextField(
                              controller: _phoneCtl,
                              label: tr.tr('phone'),
                              hint: '05xxxxxxxx',
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icon(Icons.phone_outlined, color: context.accentColor),
                              validator: (v) => (v != null && v.trim().length >= 8)
                                  ? null
                                  : tr.tr('phoneRequired'),
                            ),
                            const SizedBox(height: 14),

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
                              text: tr.tr('createAccountButton'),
                              isLoading: isLoading,
                              onPressed: isLoading ? null : _submitRegister,
                              icon: Icons.check_circle_outline_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Back to login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tr.tr('alreadyHaveAccount'),
                            style: TextStyle(color: context.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              tr.tr('login'),
                              style: TextStyle(
                                color: context.accentColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
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
}
