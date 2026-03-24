import 'package:flutter/foundation.dart';

/// Application configuration and constants.
class AppConfig {
  // API Configuration
  static const String _defaultLocalApiUrl = 'http://62.171.185.248/api/v1';
  static const String _defaultAndroidApiUrl = 'http://62.171.185.248/api/v1';

  /// Uses an override when provided, otherwise selects a sensible local default.
  ///
  /// Override example:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8000/api/v1
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) {
      return override;
    }

    if (kIsWeb) {
      return _defaultLocalApiUrl;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _defaultAndroidApiUrl;
      default:
        return _defaultLocalApiUrl;
    }
  }

  static const String registerEndpoint = '/auth/register';
  static const String verifyEmailEndpoint = '/auth/verify-email';
  static const String resendVerificationEndpoint = '/auth/resend-verification';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String loginEndpoint = '/auth/login';
  static const String onboardingEndpoint = '/onboarding';
  static const String focusSessionEventEndpoint = '/stats/events/focus-session';
  static const String blockScreenEventEndpoint = '/stats/events/block-screen';
  static const String todayStatsEndpoint = '/stats/me/today';
  static const String analyticsEndpoint = '/stats/me/analytics';
  static const String leaderboardEndpoint = '/leaderboard';

  // Storage Keys
  static const String tokenKey = 'access_token';
  static const String userKey = 'user_data';

  // App Settings
  static const String appName = 'No To Distraction';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Validation
  static const int minPasswordLength = 8;
  static const int minNameLength = 2;
  static const int minFocusGoal = 15; // minutes
  static const int maxFocusGoal = 480; // 8 hours
}

/// Time-related constants
class TimeConstants {
  static const List<String> hours = [
    '00',
    '01',
    '02',
    '03',
    '04',
    '05',
    '06',
    '07',
    '08',
    '09',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
    '21',
    '22',
    '23',
  ];

  static const List<String> minutes = ['00', '15', '30', '45'];
}

/// Error messages
class ErrorMessages {
  static const String invalidEmail = 'Please enter a valid email';
  static const String shortPassword = 'Password must be at least 8 characters';
  static const String weakPassword =
      'Password must contain uppercase, lowercase, and number';
  static const String shortName = 'Name must be at least 2 characters';
  static const String emailInUse = 'Email already registered';
  static const String invalidCredentials = 'Invalid email or password';
  static const String verifyEmailRequired =
      'Please verify your email before login';
  static const String emailNotRegistered = 'Email not registered';
  static const String invalidResetCode = 'Invalid reset code';
  static const String resetCodeExpired = 'Reset code expired';
  static const String networkError =
      'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again.';
  static const String unexpectedError = 'An unexpected error occurred';
}

/// Success messages
class SuccessMessages {
  static const String registrationSuccess = 'Account created successfully';
  static const String verificationCodeSent =
      'Verification code sent to your email';
  static const String resetCodeSent = 'Password reset code sent to your email';
  static const String passwordResetSuccess = 'Password reset successful';
  static const String emailVerified = 'Email verified successfully';
  static const String loginSuccess = 'Logged in successfully';
  static const String onboardingSuccess = 'Preferences saved successfully';
}
