/// Synapse — Neuro-Minimalist Signup Screen.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import 'package:no_to_distraction/providers/auth_provider.dart';
import 'package:no_to_distraction/theme/app_theme.dart';
import 'package:no_to_distraction/widgets/common/form_widgets.dart';
import 'package:no_to_distraction/widgets/common/password_strength_bar.dart';
import 'package:no_to_distraction/widgets/common/soft_back_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isPasswordStrong(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  Future<void> _handleSignup(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms')),
      );
      return;
    }

    final success = await authProvider.register(
      email: _emailController.text,
      password: _passwordController.text,
      name: _nameController.text,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code sent. Check your email.'),
        ),
      );
      Navigator.of(context).pushNamed('/verify-email');
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacingMd),

              // ── Back button ──
              const SoftBackButton(),
              const SizedBox(height: AppTheme.spacingMd),

              // ── Header ──
              Text('Create Account', style: AppTheme.headingLarge),
              const SizedBox(height: AppTheme.spacingXs),
              Text('Join and start focusing', style: AppTheme.bodyMedium),
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
                        children: [
                          if (authProvider.errorMessage != null) ...[
                            ErrorMessage(message: authProvider.errorMessage),
                            const SizedBox(height: AppTheme.spacingMd),
                          ],

                          FormInputField(
                            label: 'Full Name',
                            hint: 'Your name',
                            prefixIcon: Icons.person_outline_rounded,
                            controller: _nameController,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Name is required';
                              }
                              if ((value?.length ?? 0) < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingMd),

                          FormInputField(
                            label: 'Email',
                            hint: 'you@example.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Email is required';
                              }
                              if (!EmailValidator.validate(value!)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingMd),

                          FormInputField(
                            label: 'Password',
                            hint: 'At least 8 characters',
                            prefixIcon: Icons.lock_outline_rounded,
                            controller: _passwordController,
                            obscureText: true,
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Password is required';
                              }
                              if (!_isPasswordStrong(value!)) {
                                return 'Needs uppercase, lowercase & number';
                              }
                              return null;
                            },
                          ),

                          if (_passwordController.text.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spacingSm),
                            PasswordStrengthBar(
                              password: _passwordController.text,
                            ),
                          ],
                          const SizedBox(height: AppTheme.spacingMd),

                          FormInputField(
                            label: 'Confirm Password',
                            hint: 'Re-enter your password',
                            prefixIcon: Icons.lock_outline_rounded,
                            controller: _confirmPasswordController,
                            obscureText: true,
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please confirm password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingMd),

                          // ── Terms toggle ──
                          GestureDetector(
                            onTap: () => setState(
                              () => _agreedToTerms = !_agreedToTerms,
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: _agreedToTerms
                                        ? AppTheme.primaryColor
                                        : AppTheme.inputFillColor,
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      color: _agreedToTerms
                                          ? AppTheme.primaryColor
                                          : AppTheme.borderColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: _agreedToTerms
                                      ? const Icon(
                                          Icons.check,
                                          size: 13,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: AppTheme.spacingSm),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'I agree to the ',
                                      style: AppTheme.bodySmall,
                                      children: [
                                        TextSpan(
                                          text: 'Terms and Conditions',
                                          style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingLg),

                          GradientButton(
                            label: 'Create Account',
                            isLoading: authProvider.isLoading,
                            onPressed: authProvider.isLoading
                                ? null
                                : () => _handleSignup(authProvider),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // ── Login link ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?  ', style: AppTheme.bodySmall),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/login'),
                    child: Text(
                      'Sign in',
                      style: GoogleFonts.inter(
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


