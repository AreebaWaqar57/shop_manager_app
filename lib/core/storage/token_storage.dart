import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class TokenStorage {
  TokenStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<String?> getAccessToken() => _storage.read(key: _accessKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}