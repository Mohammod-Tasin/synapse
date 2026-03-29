/// Email verification screen for new users.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:no_to_distraction/providers/auth_provider.dart';
import 'package:no_to_distraction/providers/stats_provider.dart';
import 'package:no_to_distraction/theme/app_theme.dart';
import 'package:no_to_distraction/widgets/common/form_widgets.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode(AuthProvider authProvider) async {
    final email = authProvider.pendingVerificationEmail;
    final code = _codeController.text.trim();

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification session expired. Sign up again.'),
        ),
      );
      return;
    }

    if (code.length != 6 || int.tryParse(code) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit code.')),
      );
      return;
    }

    final success = await authProvider.verifyEmail(email: email, code: code);
    if (!mounted) return;

    if (success) {
      // Initialize stats for the newly verified user
      context.read<StatsProvider>().refreshAll();
      
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ??
                'Verification failed. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _resendCode(AuthProvider authProvider) async {
    final email = authProvider.pendingVerificationEmail;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification session expired. Sign up again.'),
        ),
      );
      return;
    }

    final success = await authProvider.resendVerificationCode(email: email);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Verification code resent successfully.'
              : (authProvider.errorMessage ??
                    'Failed to resend verification code.'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Email Verification'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final email = authProvider.pendingVerificationEmail ?? '';

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.spacingLg),
                    Text('Verify Your Email', style: AppTheme.headingLarge),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      email.isEmpty
                          ? 'Enter the 6-digit code sent to your email.'
                          : 'Enter the 6-digit code sent to $email',
                      style: AppTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingXl),
                    ErrorMessage(message: authProvider.errorMessage),
                    if (authProvider.errorMessage != null)
                      const SizedBox(height: AppTheme.spacingMd),
                    FormInputField(
                      label: 'Verification Code',
                      hint: 'Enter 6-digit code',
                      prefixIcon: Icons.verified_outlined,
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      validator: (_) => null,
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () => _verifyCode(authProvider),
                        child: authProvider.isLoading
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
                            : const Text('Verify Email'),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Center(
                      child: TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () => _resendCode(authProvider),
                        child: const Text('Resend Code'),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        child: const Text('Back'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
