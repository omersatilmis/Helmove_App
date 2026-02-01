import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();

  Future<void> saveUserId(String userId);
  Future<String?> getUserId();

  Future<void> saveUsername(String username);
  Future<String?> getUsername();

  Future<void> clearAuthData();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _tokenKey = 'AUTH_TOKEN';
  static const String _userIdKey = 'USER_ID';
  static const String _usernameKey = 'USER_NAME';

  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> saveToken(String token) async {
    await sharedPreferences.setString(_tokenKey, token);
  }

  @override
  Future<String?> getToken() async {
    return sharedPreferences.getString(_tokenKey);
  }

  @override
  Future<void> deleteToken() async {
    await sharedPreferences.remove(_tokenKey);
  }

  @override
  Future<void> saveUserId(String userId) async {
    await sharedPreferences.setString(_userIdKey, userId);
  }

  @override
  Future<String?> getUserId() async {
    return sharedPreferences.getString(_userIdKey);
  }

  @override
  Future<void> saveUsername(String username) async {
    await sharedPreferences.setString(_usernameKey, username);
  }

  @override
  Future<String?> getUsername() async {
    return sharedPreferences.getString(_usernameKey);
  }

  @override
  Future<void> clearAuthData() async {
    await sharedPreferences.remove(_tokenKey);
    await sharedPreferences.remove(_userIdKey);
    await sharedPreferences.remove(_usernameKey);
  }
}
