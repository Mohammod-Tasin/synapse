/// Synapse — Neuro-Minimalist Login Screen.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import 'package:no_to_distraction/providers/auth_provider.dart';
import 'package:no_to_distraction/config/app_config.dart';
import 'package:no_to_distraction/theme/app_theme.dart';
import 'package:no_to_distraction/widgets/form_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await authProvider.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!')),
      );
      return;
    }

    if (!mounted) return;

    if (authProvider.errorMessage == ErrorMessages.verifyEmailRequired) {
      authProvider.startEmailVerificationFlow(_emailController.text.trim());
      Navigator.of(context).pushNamed('/verify-email');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your email. A code can be resent there.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppTheme.spacingXxl),

              // ── App Logo / Branding ──
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(
                'Synapse',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text('Welcome back', style: AppTheme.bodyMedium),
              const SizedBox(height: AppTheme.spacingXl),

              // ── Form Card ──
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: AppTheme.softCard(),
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (authProvider.errorMessage != null) ...[
                            ErrorMessage(message: authProvider.errorMessage),
                            const SizedBox(height: AppTheme.spacingMd),
                          ],

                          FormInputField(
                            label: 'Email',
                            hint: 'you@example.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Email is required';
                              if (!EmailValidator.validate(value!)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingMd),

                          FormInputField(
                            label: 'Password',
                            hint: 'Your password',
                            prefixIcon: Icons.lock_outline_rounded,
                            controller: _passwordController,
                            obscureText: true,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Password is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingSm),

                          // ── Remember me + Forgot password ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setState(
                                  () => _rememberMe = !_rememberMe,
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _rememberMe
                                            ? AppTheme.primaryColor
                                            : AppTheme.inputFillColor,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _rememberMe
                                              ? AppTheme.primaryColor
                                              : AppTheme.borderColor,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: _rememberMe
                                          ? const Icon(
                                              Icons.check,
                                              size: 12,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remember me',
                                      style: AppTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed('/forgot-password');
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot password?',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingLg),

                          // ── Login Button ──
                          GradientButton(
                            label: 'Sign In',
                            isLoading: authProvider.isLoading,
                            onPressed: authProvider.isLoading
                                ? null
                                : () => _handleLogin(authProvider),
                          ),
                          const SizedBox(height: AppTheme.spacingLg),

                          // ── Divider ──
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: AppTheme.borderColor,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingMd,
                                ),
                                child: Text(
                                  'or continue with',
                                  style: AppTheme.bodySmall,
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: AppTheme.borderColor,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingMd),

                          // ── Google stub button ──
                          _SocialButton(
                            label: 'Continue with Google',
                            icon: Icons.g_mobiledata_rounded,
                            iconColor: const Color(0xFF4285F4),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Google login coming soon'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // ── Sign up link ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?  ",
                    style: AppTheme.bodySmall,
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed('/signup'),
                    child: Text(
                      'Create one',
                      style: GoogleFonts.poppins(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft social login button (decorative — not wired to any OAuth).
class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.inputFillColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(color: AppTheme.borderColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
