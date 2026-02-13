import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();

  Future<void> saveRefreshToken(String refreshToken);
  Future<String?> getRefreshToken();
  Future<void> deleteRefreshToken();

  Future<void> saveUserId(int userId);
  Future<int?> getUserId();

  Future<void> saveUsername(String username);
  Future<String?> getUsername();

  Future<void> clearAuthData();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _legacyAccessTokenKey = 'AUTH_TOKEN';
  static const String _accessTokenKey = 'AUTH_ACCESS_TOKEN';
  static const String _refreshTokenKey = 'AUTH_REFRESH_TOKEN';
  static const String _userIdKey = 'USER_ID';
  static const String _usernameKey = 'USER_NAME';

  final SharedPreferences sharedPreferences;
  final FlutterSecureStorage secureStorage;

  AuthLocalDataSourceImpl({
    required this.sharedPreferences,
    required this.secureStorage,
  });

  @override
  Future<void> saveToken(String token) async {
    await secureStorage.write(key: _accessTokenKey, value: token);
    await sharedPreferences.remove(_legacyAccessTokenKey);
  }

  @override
  Future<String?> getToken() async {
    final token = await secureStorage.read(key: _accessTokenKey);
    if (token != null && token.isNotEmpty) return token;

    // Migration path: old builds stored access token in SharedPreferences.
    await sharedPreferences.reload();
    final legacy = sharedPreferences.getString(_legacyAccessTokenKey);
    if (legacy != null && legacy.isNotEmpty) {
      await secureStorage.write(key: _accessTokenKey, value: legacy);
      await sharedPreferences.remove(_legacyAccessTokenKey);
      return legacy;
    }
    return null;
  }

  @override
  Future<void> deleteToken() async {
    await secureStorage.delete(key: _accessTokenKey);
    await sharedPreferences.remove(_legacyAccessTokenKey);
  }

  @override
  Future<void> saveRefreshToken(String refreshToken) async {
    await secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    final token = await secureStorage.read(key: _refreshTokenKey);
    if (token != null && token.isNotEmpty) return token;
    return null;
  }

  @override
  Future<void> deleteRefreshToken() async {
    await secureStorage.delete(key: _refreshTokenKey);
  }

  @override
  Future<void> saveUserId(int userId) async {
    await sharedPreferences.setString(_userIdKey, userId.toString());
  }

  @override
  Future<int?> getUserId() async {
    await sharedPreferences.reload();
    final idStr = sharedPreferences.getString(_userIdKey);
    if (idStr == null) return null;
    return int.tryParse(idStr);
  }

  @override
  Future<void> saveUsername(String username) async {
    await sharedPreferences.setString(_usernameKey, username);
  }

  @override
  Future<String?> getUsername() async {
    await sharedPreferences.reload();
    return sharedPreferences.getString(_usernameKey);
  }

  @override
  Future<void> clearAuthData() async {
    await deleteToken();
    await deleteRefreshToken();
    await sharedPreferences.remove(_userIdKey);
    await sharedPreferences.remove(_usernameKey);
  }
}
