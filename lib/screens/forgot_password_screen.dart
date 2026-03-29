/// Synapse — Neuro-Minimalist Forgot Password Screen.
/// Features a calm animated success state after code is sent.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:email_validator/email_validator.dart';
import 'package:no_to_distraction/services/api_service.dart';
import 'package:no_to_distraction/theme/app_theme.dart';
import 'package:no_to_distraction/widgets/form_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _apiService = ApiService();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  String? _error;

  // Animation for the success state
  late AnimationController _successAnimCtrl;
  late Animation<double> _successScale;
  late Animation<double> _successFade;

  @override
  void initState() {
    super.initState();
    _successAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _successAnimCtrl, curve: Curves.elasticOut),
    );
    _successFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successAnimCtrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _successAnimCtrl.dispose();
    super.dispose();
  }

  bool _isPasswordStrong(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (!EmailValidator.validate(email)) {
      setState(() => _error = 'Please enter a valid email');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiService.forgotPassword(email: email);
      if (!mounted) return;
      setState(() => _codeSent = true);
      _successAnimCtrl.forward();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reset code sent to your email.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!EmailValidator.validate(email)) {
      setState(() => _error = 'Please enter a valid email');
      return;
    }
    if (code.length != 6 || int.tryParse(code) == null) {
      setState(() => _error = 'Please enter a valid 6-digit code');
      return;
    }
    if (!_isPasswordStrong(newPassword)) {
      setState(() {
        _error =
            'Password must be 8+ characters with uppercase and a number';
      });
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiService.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successful. Please login.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.inputFillColor,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              Text('Reset Password', style: AppTheme.headingLarge),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                _codeSent
                    ? 'Enter the code sent to your email.'
                    : 'Enter your registered email to receive a reset code.',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // ── Email sent success animation ──
              if (_codeSent)
                FadeTransition(
                  opacity: _successFade,
                  child: ScaleTransition(
                    scale: _successScale,
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacingMd),
                      margin: const EdgeInsets.only(
                          bottom: AppTheme.spacingMd),
                      decoration: AppTheme.softCard(
                        color: AppTheme.successColor.withValues(alpha: 0.08),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mark_email_read_rounded,
                              color: AppTheme.successColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email sent!',
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: AppTheme.successColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Check your inbox for the 6-digit reset code.',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.successColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Form card ──
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: AppTheme.softCard(),
                child: Column(
                  children: [
                    if (_error != null) ...[
                      ErrorMessage(message: _error),
                      const SizedBox(height: AppTheme.spacingMd),
                    ],

                    FormInputField(
                      label: 'Email',
                      hint: 'you@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                      validator: (_) => null,
                    ),

                    // Code + new password fields revealed smoothly
                    AnimatedSize(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      child: _codeSent
                          ? Column(
                              children: [
                                const SizedBox(height: AppTheme.spacingMd),
                                FormInputField(
                                  label: 'Reset Code',
                                  hint: '6-digit code',
                                  prefixIcon:
                                      Icons.verified_user_outlined,
                                  keyboardType: TextInputType.number,
                                  controller: _codeController,
                                  validator: (_) => null,
                                ),
                                const SizedBox(height: AppTheme.spacingMd),
                                FormInputField(
                                  label: 'New Password',
                                  hint: 'Minimum 8 characters',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: true,
                                  controller: _newPasswordController,
                                  validator: (_) => null,
                                ),
                                const SizedBox(height: AppTheme.spacingMd),
                                FormInputField(
                                  label: 'Confirm New Password',
                                  hint: 'Re-enter password',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: true,
                                  controller: _confirmPasswordController,
                                  validator: (_) => null,
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    GradientButton(
                      label: _codeSent ? 'Reset Password' : 'Send Reset Code',
                      isLoading: _isLoading,
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_codeSent) {
                                _resetPassword();
                              } else {
                                _sendCode();
                              }
                            },
                    ),

                    if (_codeSent) ...[
                      const SizedBox(height: AppTheme.spacingMd),
                      TextButton(
                        onPressed: _isLoading ? null : _sendCode,
                        child: Text(
                          'Resend Code',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }
}
