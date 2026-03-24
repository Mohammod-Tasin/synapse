/// Secure token storage service using flutter_secure_storage.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:no_to_distraction/models/user.dart';

class SecureStorageService {
  static const _tokenKey = 'access_token';
  static const _userKey = 'user_data';

  final _storage = const FlutterSecureStorage();

  /// Save access token securely.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Retrieve access token.
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Check if token exists.
  Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Save user data.
  Future<void> saveUser(User user) async {
    final userJson = jsonEncode(user.toJson());
    await _storage.write(key: _userKey, value: userJson);
  }

  /// Retrieve user data.
  Future<User?> getUser() async {
    final userJson = await _storage.read(key: _userKey);
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
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
