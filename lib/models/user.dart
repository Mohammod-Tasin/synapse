// User-related data models.

/// Represents a user in the application.
class User {
  final String id;
  final String email;
  final String name;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final int totalPoints;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.totalPoints,
  });

  /// Create a User from JSON (API response).
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convert User to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'onboarding_completed': onboardingCompleted,
      'created_at': createdAt.toIso8601String(),
      'total_points': totalPoints,
    };
  }

  /// Create a copy with optional new values.
  User copyWith({
    String? id,
    String? email,
    String? name,
    bool? onboardingCompleted,
    DateTime? createdAt,
    int? totalPoints,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      totalPoints: totalPoints ?? this.totalPoints,
    );
  }

  @override
  String toString() => 'User(id: $id, email: $email, name: $name)';
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
