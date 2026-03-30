import 'package:flutter/material.dart';
import 'package:no_to_distraction/screens/login_screen.dart';
import 'package:no_to_distraction/screens/forgot_password_screen.dart';
import 'package:no_to_distraction/screens/signup_screen.dart';
import 'package:no_to_distraction/screens/verify_email_screen.dart';
import 'package:no_to_distraction/screens/onboarding_screen.dart';
import 'package:no_to_distraction/screens/home_screen.dart';
import 'package:no_to_distraction/screens/today_stats_screen.dart';
import 'package:no_to_distraction/screens/analytics_screen.dart';
import 'package:no_to_distraction/screens/leaderboard_screen.dart';
import 'package:no_to_distraction/screens/permissions_screen.dart';
import 'package:no_to_distraction/screens/quick_block_screen.dart';
import 'package:no_to_distraction/screens/distracting_apps_screen.dart';
import 'package:no_to_distraction/screens/profile_screen.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/login': (context) => const LoginScreen(),
      '/forgot-password': (context) => const ForgotPasswordScreen(),
      '/signup': (context) => const SignupScreen(),
      '/verify-email': (context) => const VerifyEmailScreen(),
      '/onboarding': (context) => const OnboardingScreen(),
      '/permissions': (context) => const PermissionsScreen(),
      '/home': (context) => const HomeScreen(),
      '/today-stats': (context) => const TodayStatsScreen(),
      '/analytics': (context) => const AnalyticsScreen(),
      '/leaderboard': (context) => const LeaderboardScreen(),
      '/quick-block': (context) => const QuickBlockScreen(),
      '/distracting-apps': (context) => const DistractingAppsScreen(),
      '/profile': (context) => const ProfileScreen(),
    };
  }
}
