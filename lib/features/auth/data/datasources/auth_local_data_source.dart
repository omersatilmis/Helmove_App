import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();

  Future<void> saveUserId(int userId);
  Future<int?> getUserId();

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
    await sharedPreferences.reload();
    return sharedPreferences.getString(_tokenKey);
  }

  @override
  Future<void> deleteToken() async {
    await sharedPreferences.remove(_tokenKey);
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
    await sharedPreferences.remove(_tokenKey);
    await sharedPreferences.remove(_userIdKey);
    await sharedPreferences.remove(_usernameKey);
  }
}
