/// HTTP API service for backend communication.
library;

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:no_to_distraction/config/app_config.dart';
import 'package:no_to_distraction/models/auth.dart';
import 'package:no_to_distraction/models/stats.dart';
import 'package:no_to_distraction/models/user.dart';
import 'package:no_to_distraction/services/secure_storage_service.dart';

class ApiService {
  final SecureStorageService _storage = SecureStorageService();

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

  /// Submit onboarding preferences (requires authentication).
  Future<void> submitOnboarding({required OnboardingData data}) async {
    final token = await _storage.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http
        .post(
          Uri.parse('$_baseUrl${AppConfig.onboardingEndpoint}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(data.toJson()),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      // Update user data with onboarding completion
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final user = User.fromJson(responseData['user'] as Map<String, dynamic>);
      await _storage.saveUser(user);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please login again.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        _resolveErrorMessage(response, ErrorMessages.serverError),
      );
    }
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

  Future<Map<String, String>> _authHeaders() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<PointsEventResponse> logFocusSession({
    required int durationMinutes,
  }) async {
    final headers = await _authHeaders();
    final response = await http
        .post(
          Uri.parse('$_baseUrl${AppConfig.focusSessionEventEndpoint}'),
          headers: headers,
          body: jsonEncode({'duration_minutes': durationMinutes}),
        )
        .timeout(_timeout);

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
    final headers = await _authHeaders();
    final response = await http
        .post(
          Uri.parse('$_baseUrl${AppConfig.blockScreenEventEndpoint}'),
          headers: headers,
          body: jsonEncode({
            'reason': reason,
            'points_penalty': pointsPenalty,
            'package_name': packageName,
          }),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      return PointsEventResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(_resolveErrorMessage(response, ErrorMessages.serverError));
  }

  Future<TodayStats> getTodayStats() async {
    final headers = await _authHeaders();
    final response = await http
        .get(
          Uri.parse('$_baseUrl${AppConfig.todayStatsEndpoint}'),
          headers: headers,
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      return TodayStats.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(_resolveErrorMessage(response, ErrorMessages.serverError));
  }

  Future<AnalyticsResponse> getAnalytics({int days = 7}) async {
    final headers = await _authHeaders();
    final response = await http
        .get(
          Uri.parse('$_baseUrl${AppConfig.analyticsEndpoint}?days=$days'),
          headers: headers,
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      return AnalyticsResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(_resolveErrorMessage(response, ErrorMessages.serverError));
  }

  Future<LeaderboardResponse> getLeaderboard({int limit = 20}) async {
    final headers = await _authHeaders();
    final response = await http
        .get(
          Uri.parse('$_baseUrl${AppConfig.leaderboardEndpoint}?limit=$limit'),
          headers: headers,
        )
        .timeout(_timeout);

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
