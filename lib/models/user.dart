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
