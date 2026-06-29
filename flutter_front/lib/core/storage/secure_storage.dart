import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// access token만 관리. refresh token은 HttpOnly 쿠키로 백엔드가 관리하며
/// dio_cookie_manager(PersistCookieJar)가 자동으로 첨부/저장함.
class SecureStorage {
  SecureStorage._();
  static final SecureStorage instance = SecureStorage._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessTokenKey = 'access_token';

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<bool> hasAccessToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAccessToken() => _storage.delete(key: _accessTokenKey);
}