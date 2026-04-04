import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around flutter_secure_storage for token persistence.
class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  // ── Access Token ──────────────────────────────────────────
  static Future<String?> getAccessToken() => _storage.read(key: _accessKey);
  static Future<void> setAccessToken(String token) =>
      _storage.write(key: _accessKey, value: token);

  // ── Refresh Token ─────────────────────────────────────────
  static Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);
  static Future<void> setRefreshToken(String token) =>
      _storage.write(key: _refreshKey, value: token);

  // ── Clear All ─────────────────────────────────────────────
  static Future<void> clearAll() => _storage.deleteAll();

  /// Check if user has stored tokens.
  static Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
