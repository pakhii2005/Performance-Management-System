import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/models/user_model.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();
  
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyExpiresAt = 'expires_at';
  static const _keyUser = 'user_info';

  /// Saves the user authentication session to secure storage.
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required int expiresInSeconds,
    required UserModel user,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    
    final expiresAt = DateTime.now().add(Duration(seconds: expiresInSeconds));
    await _storage.write(key: _keyExpiresAt, value: expiresAt.toIso8601String());
    await _storage.write(key: _keyUser, value: jsonEncode(user.toJson()));
  }

  /// Updates only the access token and its expiration.
  static Future<void> saveAccessToken(String accessToken, int expiresInSeconds) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    final expiresAt = DateTime.now().add(Duration(seconds: expiresInSeconds));
    await _storage.write(key: _keyExpiresAt, value: expiresAt.toIso8601String());
  }

  /// Retrieves the access token.
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  /// Retrieves the refresh token.
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Retrieves the cached User information.
  static Future<UserModel?> getUser() async {
    final userStr = await _storage.read(key: _keyUser);
    if (userStr == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Checks if the access token has expired (or is close to expiring in <30 seconds).
  static Future<bool> isTokenExpired() async {
    final expiresAtStr = await _storage.read(key: _keyExpiresAt);
    if (expiresAtStr == null) return true;
    try {
      final expiresAt = DateTime.parse(expiresAtStr);
      return expiresAt.isBefore(DateTime.now().add(const Duration(seconds: 30)));
    } catch (_) {
      return true;
    }
  }

  /// Clears the authentication session.
  static Future<void> clearSession() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyExpiresAt);
    await _storage.delete(key: _keyUser);
  }
}
