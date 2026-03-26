/// Splash screen displayed on app startup.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:no_to_distraction/providers/auth_provider.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  void _initializeAuth() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();
    
    if (mounted) {
      // Navigation is handled by the main app widget
      // based on AuthProvider.status
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.psychology,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'No to Distraction',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Focus on what matters',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
