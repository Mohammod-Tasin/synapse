/// Token and user data storage using SharedPreferences for highly reliable synchronous access on cold boot.
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:no_to_distraction/models/user.dart';

class SecureStorageService {
  static const _tokenKey = 'access_token';
  static const _userKey = 'user_data';

  /// Save access token securely.
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Retrieve access token.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Check if token exists.
  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Save user data.
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_userKey, userJson);
  }

  /// Retrieve user data.
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;

    try {
      final json = jsonDecode(userJson) as Map<String, dynamic>;
      return User.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Clear all stored data (logout).
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
