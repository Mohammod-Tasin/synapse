/// Authentication state management using Provider.
library;

import 'package:flutter/foundation.dart';
import 'package:no_to_distraction/models/user.dart';
import 'package:no_to_distraction/services/api_service.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  notAuthenticated,
  onboarding,
  error,
}

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  AuthProvider() {
    ApiService.onTokenExpired = () async {
      // When a token expires, seamlessly log the user out and trigger a redirect to the login screen
      _errorMessage = 'Session expired. Please log in again.';
      await logout();
    };
  }

  // State
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  String? _pendingVerificationEmail;
  bool _isLoading = false;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get pendingVerificationEmail => _pendingVerificationEmail;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get needsOnboarding => _user != null && !_user!.onboardingCompleted;

  /// Initialize auth state on app startup.
  Future<void> initialize() async {
    _setStatus(AuthStatus.initial);
    _isLoading = true;
    notifyListeners();

    try {
      final isAuthenticated = await _apiService.isAuthenticated();
      if (isAuthenticated) {
        final user = await _apiService.getStoredUser();
        if (user != null) {
          _user = user;
          if (user.onboardingCompleted) {
            _setStatus(AuthStatus.authenticated);
          } else {
            _setStatus(AuthStatus.onboarding);
          }
        } else {
          _setStatus(AuthStatus.notAuthenticated);
        }
      } else {
        _setStatus(AuthStatus.notAuthenticated);
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize auth: ${e.toString()}';
      _setStatus(AuthStatus.error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register a new user.
  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.register(
        email: email,
        password: password,
        name: name,
      );

      _pendingVerificationEmail = response.email;
      
      if (response.user != null) {
        _user = User.fromJson(response.user!);
      }

      _setStatus(AuthStatus.notAuthenticated);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setStatus(AuthStatus.notAuthenticated);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify email code and authenticate the user.
  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.verifyEmail(email: email, code: code);
      _user = User.fromJson(response.user);
      _pendingVerificationEmail = null;

      if (_user!.onboardingCompleted) {
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.onboarding);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setStatus(AuthStatus.notAuthenticated);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Resend email verification code.
  Future<bool> resendVerificationCode({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.resendVerificationCode(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Move to verification-pending state (used for unverified login attempts).
  void startEmailVerificationFlow(String email) {
    _pendingVerificationEmail = email;
    _setStatus(AuthStatus.notAuthenticated);
    notifyListeners();
  }

  /// Login user with email and password.
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      _user = User.fromJson(response.user);

      if (_user!.onboardingCompleted) {
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.onboarding);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setStatus(AuthStatus.notAuthenticated);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Submit onboarding data.
  Future<bool> submitOnboarding({required OnboardingData data}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.submitOnboarding(data: data);

      // Update user with onboarding completion status
      if (_user != null) {
        _user = _user!.copyWith(onboardingCompleted: true);
      }

      _setStatus(AuthStatus.authenticated);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setStatus(AuthStatus.error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout user.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
      _user = null;
      _errorMessage = null;
      _setStatus(AuthStatus.notAuthenticated);
    } catch (e) {
      _errorMessage = 'Logout failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Set auth status.
  void _setStatus(AuthStatus status) {
    _status = status;
  }
}
