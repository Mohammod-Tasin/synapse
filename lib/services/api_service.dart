/// HTTP API service for backend communication.
library;

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:no_to_distraction/config/app_config.dart';
import 'package:no_to_distraction/models/auth.dart';
import 'package:no_to_distraction/models/stats.dart';
import 'package:no_to_distraction/models/user.dart';
import 'package:no_to_distraction/services/secure_storage_service.dart';

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException([this.message = 'Session expired. Please log in again.']);
  
  @override
  String toString() => message;
}

class ApiService {
  final SecureStorageService _storage = SecureStorageService();

  /// Global callback triggered when an API request encounters a 401 Unauthorized (expired token).
  static Future<void> Function()? onTokenExpired;

  static String get _baseUrl => AppConfig.baseUrl;
  static const Duration _timeout = AppConfig.apiTimeout;

  /// Register a new user.
  Future<RegisterResponse> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final request = RegisterRequest(
      email: email,
      password: password,
      name: name,
    );

    final response = await http
        .post(
          Uri.parse('$_baseUrl${AppConfig.registerEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(_timeout);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return RegisterResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(_resolveErrorMessage(response, ErrorMessages.serverError));
  }

  /// Verify email with code and authenticate user.
  Future<AuthResponse> verifyEmail({
    required String email,
    required String code,
  }) async {
    final request = VerifyEmailRequest(email: email, code: code);

    final response = await http
        .post(
          Uri.parse('$_baseUrl${AppConfig.verifyEmailEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      // Save token and user data
      await _storage.saveToken(authResponse.accessToken);
      final user = User.fromJson(authResponse.user);
      await _storage.saveUser(user);

      return authResponse;
    }

    throw Exception(_resolveErrorMessage(response, ErrorMessages.serverError));
  }

  /// Resend email verification code.
  Future<void> resendVerificationCode({required String email}) async {
    final request = ForgotPasswordRequest(email: email);

    final response = await http
        .post(
          Uri.parse('$_baseUrl${AppConfig.resendVerificationEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(_resolveErrorMessage(response, ErrorMessages.serverError));
  }

  /// Send forgot-password reset code.
  Future<void> forgotPassword({required String email}) async {
    final request = ForgotPasswordRequest(email: email);

    final response = await http
        .post(
          Uri.parse('$_baseUrl${AppConfig.forgotPasswordEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(_resolveErrorMessage(response, ErrorMessages.serverError));
  }

  /// Reset password with verification code.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final request = ResetPasswordRequest(
      email: email,
      code: code,
      newPassword: newPassword,
    );

    final response = await http
        .post(
          Uri.parse('$_baseUrl${AppConfig.resetPasswordEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(_resolveErrorMessage(response, ErrorMessages.serverError));
  }

  /// Login user with email and password.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final request = LoginRequest(email: email, password: password);

    final response = await http
        .post(
          Uri.parse('$_baseUrl${AppConfig.loginEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      // Save token and user data
      await _storage.saveToken(authResponse.accessToken);
      final user = User.fromJson(authResponse.user);
      await _storage.saveUser(user);

      return authResponse;
    }

    if (response.statusCode == 403) {
      throw Exception(ErrorMessages.verifyEmailRequired);
    }

    if (response.statusCode == 401) {
      throw Exception(ErrorMessages.invalidCredentials);
    }

    throw Exception(_resolveErrorMessage(response, ErrorMessages.serverError));
  }

  /// Wrapper for authenticated API requests
  Future<http.Response> _request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      onTokenExpired?.call();
      throw TokenExpiredException();
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final url = Uri.parse('$_baseUrl$endpoint');
    http.Response response;

    // Execute the request
    if (method == 'POST') {
      response = await http.post(url, headers: headers, body: body != null ? jsonEncode(body) : null).timeout(_timeout);
    } else if (method == 'GET') {
      response = await http.get(url, headers: headers).timeout(_timeout);
    } else {
      throw UnsupportedError('HTTP method $method not supported');
    }

    // Intercept 401 Unauthorized token expiration
    if (response.statusCode == 401) {
      await logout(); // Clear local storage proactively
      onTokenExpired?.call();
      throw TokenExpiredException();
    }

    return response;
  }

  /// Submit onboarding preferences (requires authentication).
  Future<void> submitOnboarding({required OnboardingData data}) async {
    final response = await _request(
      method: 'POST',
      endpoint: AppConfig.onboardingEndpoint,
      body: data.toJson(),
    );

    if (response.statusCode == 200) {
      // Update user data with onboarding completion
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final user = User.fromJson(responseData['user'] as Map<String, dynamic>);
      await _storage.saveUser(user);
    } else {
      throw Exception(_resolveErrorMessage(response, ErrorMessages.serverError));
    }
  }

  /// Get onboarding preferences (requires authentication).
  Future<OnboardingData?> getOnboardingData() async {
    try {
      final response = await _request(
        method: 'GET',
        endpoint: AppConfig.onboardingEndpoint,
      );

      if (response.statusCode == 200) {
        return OnboardingData.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
    } catch (_) {
      // Ignored: returning null if mapping fails or endpoint is not implemented
    }
    return null;
  }

  /// Logout user (clear local storage).
  Future<void> logout() async {
    await _storage.clearAll();
  }

  /// Check if user is authenticated.
  Future<bool> isAuthenticated() async {
    return await _storage.hasToken();
  }

  /// Get stored user data.
  Future<User?> getStoredUser() async {
    return await _storage.getUser();
  }

  /// Get current access token.
  Future<String?> getToken() async {
    return await _storage.getToken();
  }

  Future<PointsEventResponse> logFocusSession({
    required int durationMinutes,
  }) async {
    final response = await _request(
      method: 'POST',
      endpoint: AppConfig.focusSessionEventEndpoint,
      body: {'duration_minutes': durationMinutes},
    );

    if (response.statusCode == 200) {
      return PointsEventResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(_resolveErrorMessage(response, ErrorMessages.serverError));
  }

  Future<PointsEventResponse> logBlockScreen({
    required String reason,
    int pointsPenalty = 1,
    String? packageName,
  }) async {
    final response = await _request(
      method: 'POST',
      endpoint: AppConfig.blockScreenEventEndpoint,
      body: {
        'reason': reason,
        'points_penalty': pointsPenalty,
        if (packageName != null) 'package_name': packageName,
      },
    );

    if (response.statusCode == 200) {
      return PointsEventResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(_resolveErrorMessage(response, ErrorMessages.serverError));
  }

  Future<TodayStats> getTodayStats() async {
    final response = await _request(
      method: 'GET',
      endpoint: AppConfig.todayStatsEndpoint,
    );

    if (response.statusCode == 200) {
      return TodayStats.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(_resolveErrorMessage(response, ErrorMessages.serverError));
  }

  Future<AnalyticsResponse> getAnalytics({int days = 7}) async {
    final response = await _request(
      method: 'GET',
      endpoint: '${AppConfig.analyticsEndpoint}?days=$days',
    );

    if (response.statusCode == 200) {
      return AnalyticsResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(_resolveErrorMessage(response, ErrorMessages.serverError));
  }

  Future<LeaderboardResponse> getLeaderboard({int limit = 20}) async {
    final response = await _request(
      method: 'GET',
      endpoint: '${AppConfig.leaderboardEndpoint}?limit=$limit',
    );

    if (response.statusCode == 200) {
      return LeaderboardResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(_resolveErrorMessage(response, ErrorMessages.serverError));
  }

  /// Extract API error message when available.
  String _resolveErrorMessage(http.Response response, String fallback) {
    try {
      final error = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = error['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
    } catch (_) {
      // Ignore parse errors and fallback.
    }

    return fallback;
  }
}
