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
