/// Forgot password screen with request-code and reset-password flow.
library;

import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:no_to_distraction/services/api_service.dart';
import 'package:no_to_distraction/theme/app_theme.dart';
import 'package:no_to_distraction/widgets/form_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _apiService = ApiService();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _codeSent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset code sent to your email.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            'Password must contain at least 8 characters, one uppercase and one number';
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
        const SnackBar(
          content: Text('Password reset successful. Please login.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reset Password', style: AppTheme.headingLarge),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  _codeSent
                      ? 'Enter the code sent to your email and set a new password.'
                      : 'Enter your registered email to receive a reset code.',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingXl),
                ErrorMessage(message: _error),
                if (_error != null) const SizedBox(height: AppTheme.spacingMd),
                FormInputField(
                  label: 'Email',
                  hint: 'Enter your registered email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  controller: _emailController,
                  validator: (_) => null,
                ),
                const SizedBox(height: AppTheme.spacingMd),
                if (_codeSent) ...[
                  FormInputField(
                    label: 'Reset Code',
                    hint: 'Enter 6-digit code',
                    prefixIcon: Icons.verified_user_outlined,
                    keyboardType: TextInputType.number,
                    controller: _codeController,
                    validator: (_) => null,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  FormInputField(
                    label: 'New Password',
                    hint: 'Enter new password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    controller: _newPasswordController,
                    validator: (_) => null,
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  FormInputField(
                    label: 'Confirm New Password',
                    hint: 'Re-enter new password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    controller: _confirmPasswordController,
                    validator: (_) => null,
                  ),
                ],
                const SizedBox(height: AppTheme.spacingLg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_codeSent) {
                              _resetPassword();
                            } else {
                              _sendCode();
                            }
                          },
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _codeSent ? 'Reset Password' : 'Send Reset Code',
                          ),
                  ),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : _sendCode,
                      child: const Text('Resend Code'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
