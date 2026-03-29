/// Authentication request/response models.
library;

/// Request payload for user registration.
class RegisterRequest {
  final String email;
  final String password;
  final String name;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.name,
  });

  /// Convert to JSON for API request.
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password, 'name': name};
  }
}

/// Request payload for verifying email with code.
class VerifyEmailRequest {
  final String email;
  final String code;

  VerifyEmailRequest({required this.email, required this.code});

  /// Convert to JSON for API request.
  Map<String, dynamic> toJson() {
    return {'email': email, 'code': code};
  }
}

/// Request payload for forgot password.
class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  /// Convert to JSON for API request.
  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

/// Request payload for resetting password.
class ResetPasswordRequest {
  final String email;
  final String code;
  final String newPassword;

  ResetPasswordRequest({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  /// Convert to JSON for API request.
  Map<String, dynamic> toJson() {
    return {'email': email, 'code': code, 'new_password': newPassword};
  }
}

/// Response from registration endpoint.
class RegisterResponse {
  final String message;
  final String email;
  final Map<String, dynamic>? user;

  RegisterResponse({required this.message, required this.email, this.user});

  /// Create from JSON (API response).
  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      message: json['message'] as String? ?? '',
      email: json['email'] as String? ?? '',
      user: json['user'] as Map<String, dynamic>?,
    );
  }
}

/// Request payload for user login.
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  /// Convert to JSON for API request.
  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

/// Response from authentication endpoints.
class AuthResponse {
  final String accessToken;
  final String tokenType;
  final Map<String, dynamic> user;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  /// Create from JSON (API response).
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: json['user'] as Map<String, dynamic>,
    );
  }
}

/// Represents onboarding/preferences data.
class OnboardingData {
  final int dailyFocusGoalMinutes;
  final TimeRange studyTime;
  final TimeRange sleepTime;
  final TimeRange institutionTime;

  OnboardingData({
    required this.dailyFocusGoalMinutes,
    required this.studyTime,
    required this.sleepTime,
    required this.institutionTime,
  });

  /// Create from JSON (API response).
  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      dailyFocusGoalMinutes: json['daily_focus_goal_minutes'] as int,
      studyTime: TimeRange.fromStrings(
        json['study_time_start'] as String,
        json['study_time_end'] as String,
      ),
      sleepTime: TimeRange.fromStrings(
        json['sleep_time_start'] as String,
        json['sleep_time_end'] as String,
      ),
      institutionTime: TimeRange.fromStrings(
        json['institution_time_start'] as String,
        json['institution_time_end'] as String,
      ),
    );
  }

  /// Convert to JSON for API request.
  Map<String, dynamic> toJson() {
    return {
      'daily_focus_goal_minutes': dailyFocusGoalMinutes,
      'study_time_start': studyTime.startTimeString,
      'study_time_end': studyTime.endTimeString,
      'sleep_time_start': sleepTime.startTimeString,
      'sleep_time_end': sleepTime.endTimeString,
      'institution_time_start': institutionTime.startTimeString,
      'institution_time_end': institutionTime.endTimeString,
    };
  }

  /// Create a copy with optional new values.
  OnboardingData copyWith({
    int? dailyFocusGoalMinutes,
    TimeRange? studyTime,
    TimeRange? sleepTime,
    TimeRange? institutionTime,
  }) {
    return OnboardingData(
      dailyFocusGoalMinutes:
          dailyFocusGoalMinutes ?? this.dailyFocusGoalMinutes,
      studyTime: studyTime ?? this.studyTime,
      sleepTime: sleepTime ?? this.sleepTime,
      institutionTime: institutionTime ?? this.institutionTime,
    );
  }
}

/// Represents a time range with start and end times.
class TimeRange {
  final AppTimeOfDay startTime;
  final AppTimeOfDay endTime;

  TimeRange({required this.startTime, required this.endTime});

  /// Create from time strings in HH:MM format.
  factory TimeRange.fromStrings(String start, String end) {
    final startParts = start.split(':');
    final endParts = end.split(':');

    return TimeRange(
      startTime: AppTimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      ),
      endTime: AppTimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      ),
    );
  }

  /// Get start time as HH:MM string.
  String get startTimeString {
    return '${startTime.hour.toString().padLeft(2, '0')}:'
        '${startTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get end time as HH:MM string.
  String get endTimeString {
    return '${endTime.hour.toString().padLeft(2, '0')}:'
        '${endTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get display string (e.g., "09:00 - 17:00").
  String get displayString {
    return '$startTimeString - $endTimeString';
  }
}

/// Represents a time of day (hour and minute).
class AppTimeOfDay {
  final int hour;
  final int minute;

  AppTimeOfDay({required this.hour, required this.minute});

  /// Get display string (e.g., "09:00").
  String get displayString {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Create a copy with optional new values.
  AppTimeOfDay copyWith({int? hour, int? minute}) {
    return AppTimeOfDay(hour: hour ?? this.hour, minute: minute ?? this.minute);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppTimeOfDay &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}
