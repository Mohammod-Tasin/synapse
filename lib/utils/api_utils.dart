import 'dart:convert';
import 'package:http/http.dart' as http;

/// Utility for resolving error messages from API responses.
class ApiUtils {
  /// Extract API error message when available.
  static String resolveErrorMessage(http.Response response, String fallback) {
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
