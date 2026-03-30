import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:no_to_distraction/providers/auth_provider.dart';
import 'package:no_to_distraction/providers/stats_provider.dart';
import 'package:no_to_distraction/screens/splash_screen.dart';
import 'package:no_to_distraction/screens/login_screen.dart';
import 'package:no_to_distraction/screens/onboarding_screen.dart';
import 'package:no_to_distraction/screens/home_screen.dart';
import 'package:no_to_distraction/theme/app_theme.dart';

/// AuthNavigator handles routing based on authentication status.
class AuthNavigator extends StatelessWidget {
  const AuthNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Initial loading state - show splash screen
        if (authProvider.status == AuthStatus.initial ||
            authProvider.status == AuthStatus.authenticating) {
          return const SplashScreen();
        }

        // Not authenticated - show login screen
        if (authProvider.status == AuthStatus.notAuthenticated) {
          return const LoginScreen();
        }

        // Authenticated but needs onboarding
        if (authProvider.status == AuthStatus.onboarding) {
          return const OnboardingScreen();
        }

        // Fully authenticated - open home directly to avoid re-gating every launch.
        if (authProvider.status == AuthStatus.authenticated) {
          // Trigger a silent refresh of stats on every successful (re)authentication
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final statsProvider = Provider.of<StatsProvider>(context, listen: false);
            if (statsProvider.todayStats == null) {
              statsProvider.refreshAll();
            }
          });
          return const HomeScreen();
        }

        // Error state - show error message with retry option
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Text('An error occurred', style: AppTheme.headingMedium),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  authProvider.errorMessage ?? 'Unknown error',
                  style: AppTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                ElevatedButton(
                  onPressed: () {
                    authProvider.initialize();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
