import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:no_to_distraction/config/app_config.dart';
import 'package:no_to_distraction/models/auth.dart';
import 'package:no_to_distraction/models/user.dart';
import 'package:no_to_distraction/services/base_api.dart';
import 'package:no_to_distraction/utils/api_utils.dart';

/// Service for authentication-related API calls.
class AuthApi extends BaseApi {
  /// Register a new user.
  Future<RegisterResponse> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final requestData = RegisterRequest(
      email: email,
      password: password,
      name: name,
    );

    final response = await http
        .post(
          Uri.parse('${BaseApi.baseUrl}${AppConfig.registerEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData.toJson()),
        )
        .timeout(BaseApi.timeout);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return RegisterResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(ApiUtils.resolveErrorMessage(response, ErrorMessages.serverError));
  }

  /// Verify email with code and authenticate user.
  Future<AuthResponse> verifyEmail({
    required String email,
    required String code,
  }) async {
    final requestData = VerifyEmailRequest(email: email, code: code);

    final response = await http
        .post(
          Uri.parse('${BaseApi.baseUrl}${AppConfig.verifyEmailEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData.toJson()),
        )
        .timeout(BaseApi.timeout);

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      // Save token and user data
      await storage.saveToken(authResponse.accessToken);
      final user = User.fromJson(authResponse.user);
      await storage.saveUser(user);

      return authResponse;
    }

    throw Exception(ApiUtils.resolveErrorMessage(response, ErrorMessages.serverError));
  }

  /// Resend email verification code.
  Future<void> resendVerificationCode({required String email}) async {
    final requestData = ForgotPasswordRequest(email: email);

    final response = await http
        .post(
          Uri.parse('${BaseApi.baseUrl}${AppConfig.resendVerificationEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData.toJson()),
        )
        .timeout(BaseApi.timeout);

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(ApiUtils.resolveErrorMessage(response, ErrorMessages.serverError));
  }

  /// Send forgot-password reset code.
  Future<void> forgotPassword({required String email}) async {
    final requestData = ForgotPasswordRequest(email: email);

    final response = await http
        .post(
          Uri.parse('${BaseApi.baseUrl}${AppConfig.forgotPasswordEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData.toJson()),
        )
        .timeout(BaseApi.timeout);

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(ApiUtils.resolveErrorMessage(response, ErrorMessages.serverError));
  }

  /// Reset password with verification code.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final requestData = ResetPasswordRequest(
      email: email,
      code: code,
      newPassword: newPassword,
    );

    final response = await http
        .post(
          Uri.parse('${BaseApi.baseUrl}${AppConfig.resetPasswordEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData.toJson()),
        )
        .timeout(BaseApi.timeout);

    if (response.statusCode == 200) {
      return;
    }

    throw Exception(ApiUtils.resolveErrorMessage(response, ErrorMessages.serverError));
  }

  /// Login user with email and password.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final requestData = LoginRequest(email: email, password: password);

    final response = await http
        .post(
          Uri.parse('${BaseApi.baseUrl}${AppConfig.loginEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData.toJson()),
        )
        .timeout(BaseApi.timeout);

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );

      // Save token and user data
      await storage.saveToken(authResponse.accessToken);
      final user = User.fromJson(authResponse.user);
      await storage.saveUser(user);

      return authResponse;
    }

    if (response.statusCode == 403) {
      throw Exception(ErrorMessages.verifyEmailRequired);
    }

    if (response.statusCode == 401) {
      throw Exception(ErrorMessages.invalidCredentials);
    }

    throw Exception(ApiUtils.resolveErrorMessage(response, ErrorMessages.serverError));
  }

  /// Submit onboarding preferences (requires authentication).
  Future<void> submitOnboarding({required OnboardingData data}) async {
    final response = await request(
      method: 'POST',
      endpoint: AppConfig.onboardingEndpoint,
      body: data.toJson(),
    );

    if (response.statusCode == 200) {
      // Update user data with onboarding completion
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final user = User.fromJson(responseData['user'] as Map<String, dynamic>);
      await storage.saveUser(user);
    } else {
      throw Exception(ApiUtils.resolveErrorMessage(response, ErrorMessages.serverError));
    }
  }

  /// Get onboarding preferences (requires authentication).
  Future<OnboardingData?> getOnboardingData() async {
    try {
      final response = await request(
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
    await storage.clearAll();
  }

  /// Check if user is authenticated.
  Future<bool> isAuthenticated() async {
    return await storage.hasToken();
  }

  /// Get stored user data.
  Future<User?> getStoredUser() async {
    return await storage.getUser();
  }

  /// Get current access token.
  Future<String?> getToken() async {
    return await storage.getToken();
  }
}
