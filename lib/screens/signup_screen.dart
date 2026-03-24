/// Signup screen for new users.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:email_validator/email_validator.dart';
import 'package:no_to_distraction/providers/auth_provider.dart';
import 'package:no_to_distraction/theme/app_theme.dart';
import 'package:no_to_distraction/widgets/form_widgets.dart';

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
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                const Text('Create Account', style: AppTheme.headingLarge),
                const SizedBox(height: AppTheme.spacingSm),
                const Text(
                  'Join us and start focusing',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingXl),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          ErrorMessage(message: authProvider.errorMessage),
                          if (authProvider.errorMessage != null)
                            const SizedBox(height: AppTheme.spacingMd),
                          FormInputField(
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            prefixIcon: Icons.person_outlined,
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
                            hint: 'Enter your email',
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
                            prefixIcon: Icons.lock_outlined,
                            controller: _passwordController,
                            obscureText: true,
                            onChanged: (value) => setState(() {}),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Password is required';
                              }
                              if (!_isPasswordStrong(value!)) {
                                return 'Password must contain uppercase, lowercase, and number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppTheme.spacingSm),
                          if (_passwordController.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppTheme.spacingMd,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _PasswordStrengthIndicator(
                                    password: _passwordController.text,
                                  ),
                                ],
                              ),
                            ),
                          FormInputField(
                            label: 'Confirm Password',
                            hint: 'Re-enter your password',
                            prefixIcon: Icons.lock_outlined,
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
                          Row(
                            children: [
                              Checkbox(
                                value: _agreedToTerms,
                                onChanged: (value) {
                                  setState(
                                    () => _agreedToTerms = value ?? false,
                                  );
                                },
                                activeColor: AppTheme.primaryColor,
                              ),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: "I agree to the ",
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
                          const SizedBox(height: AppTheme.spacingLg),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () => _handleSignup(authProvider),
                              child: authProvider.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text('Create Account'),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMd),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: AppTheme.bodySmall,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/login');
                                },
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Password strength indicator widget.
class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  bool get _hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => password.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => password.contains(RegExp(r'[0-9]'));
  bool get _hasMinLength => password.length >= 8;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Password Requirements:', style: AppTheme.bodySmall),
        const SizedBox(height: AppTheme.spacingSm),
        _RequirementCheck(met: _hasMinLength, text: 'At least 8 characters'),
        _RequirementCheck(met: _hasUppercase, text: 'One uppercase letter'),
        _RequirementCheck(met: _hasLowercase, text: 'One lowercase letter'),
        _RequirementCheck(met: _hasNumber, text: 'One number'),
      ],
    );
  }
}

class _RequirementCheck extends StatelessWidget {
  final bool met;
  final String text;

  const _RequirementCheck({required this.met, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: met ? AppTheme.successColor : AppTheme.textSecondaryColor,
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          text,
          style: AppTheme.bodySmall.copyWith(
            color: met ? AppTheme.successColor : AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}
