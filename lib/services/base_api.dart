import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:no_to_distraction/config/app_config.dart';
import 'package:no_to_distraction/services/secure_storage_service.dart';

/// Exception thrown when a token expires.
class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException([
    this.message = 'Session expired. Please log in again.',
  ]);

  @override
  String toString() => message;
}

/// Base class for all API services.
abstract class BaseApi {
  final SecureStorageService storage = SecureStorageService();

  /// Global callback triggered when an API request encounters a 401 Unauthorized (expired token).
  static Future<void> Function()? onTokenExpired;

  static String get baseUrl => AppConfig.baseUrl;
  static const Duration timeout = AppConfig.apiTimeout;

  /// Wrapper for authenticated API requests
  Future<http.Response> request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    final token = await storage.getToken();
    if (token == null || token.isEmpty) {
      print(
        'API ABORTED: Attempted to call $endpoint without a token. Ignoring to prevent false logout.',
      );
      throw Exception('Not authenticated locally');
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final url = Uri.parse('$baseUrl$endpoint');
    http.Response response;

    // Execute the request
    if (method == 'POST') {
      response = await http
          .post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);
    } else if (method == 'GET') {
      response = await http.get(url, headers: headers).timeout(timeout);
    } else {
      throw UnsupportedError('HTTP method $method not supported');
    }

    // Intercept 401 Unauthorized token expiration
    if (response.statusCode == 401) {
      print(
        'AUTO-LOGOUT TRIGGERED: Failed URL: $endpoint, Token exists locally: ${token.isNotEmpty}',
      );
      // Note: logout is handled by the AuthProvider via the onTokenExpired callback
      onTokenExpired?.call();
      throw TokenExpiredException();
    }

    return response;
  }
}
