import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/enums/user_tier.dart';

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
  Future<void> saveEmail(String email);
  Future<String?> getEmail();
  Future<void> saveFirstName(String? firstName);
  Future<String?> getFirstName();
  Future<void> saveLastName(String? lastName);
  Future<String?> getLastName();
  Future<void> saveProfileImageUrl(String? profileImageUrl);
  Future<String?> getProfileImageUrl();
  Future<void> saveFollowersCount(int count);
  Future<int?> getFollowersCount();
  Future<void> saveFollowingCount(int count);
  Future<int?> getFollowingCount();
  Future<void> saveFriendsCount(int count);
  Future<int?> getFriendsCount();
  Future<void> saveIsPremium(bool isPremium);
  Future<bool> getIsPremium();

  Future<void> saveTier(UserTier tier);
  Future<UserTier> getTier();

  Future<void> clearAuthData();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _legacyAccessTokenKey = 'AUTH_TOKEN';
  static const String _accessTokenKey = 'AUTH_ACCESS_TOKEN';
  static const String _refreshTokenKey = 'AUTH_REFRESH_TOKEN';
  static const String _userIdKey = 'USER_ID';
  static const String _usernameKey = 'USER_NAME';
  static const String _emailKey = 'USER_EMAIL';
  static const String _firstNameKey = 'USER_FIRST_NAME';
  static const String _lastNameKey = 'USER_LAST_NAME';
  static const String _profileImageUrlKey = 'USER_PROFILE_IMAGE_URL';
  static const String _followersCountKey = 'USER_FOLLOWERS_COUNT';
  static const String _followingCountKey = 'USER_FOLLOWING_COUNT';
  static const String _friendsCountKey = 'USER_FRIENDS_COUNT';
  static const String _isPremiumKey = 'USER_IS_PREMIUM';
  static const String _tierKey = 'USER_TIER_ENUM';

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
  Future<void> saveEmail(String email) async {
    await sharedPreferences.setString(_emailKey, email);
  }

  @override
  Future<String?> getEmail() async {
    await sharedPreferences.reload();
    return sharedPreferences.getString(_emailKey);
  }

  @override
  Future<void> saveFirstName(String? firstName) async {
    if (firstName == null || firstName.trim().isEmpty) {
      await sharedPreferences.remove(_firstNameKey);
      return;
    }
    await sharedPreferences.setString(_firstNameKey, firstName.trim());
  }

  @override
  Future<String?> getFirstName() async {
    await sharedPreferences.reload();
    return sharedPreferences.getString(_firstNameKey);
  }

  @override
  Future<void> saveLastName(String? lastName) async {
    if (lastName == null || lastName.trim().isEmpty) {
      await sharedPreferences.remove(_lastNameKey);
      return;
    }
    await sharedPreferences.setString(_lastNameKey, lastName.trim());
  }

  @override
  Future<String?> getLastName() async {
    await sharedPreferences.reload();
    return sharedPreferences.getString(_lastNameKey);
  }

  @override
  Future<void> saveProfileImageUrl(String? profileImageUrl) async {
    if (profileImageUrl == null || profileImageUrl.trim().isEmpty) {
      await sharedPreferences.remove(_profileImageUrlKey);
      return;
    }
    await sharedPreferences.setString(
      _profileImageUrlKey,
      profileImageUrl.trim(),
    );
  }

  @override
  Future<String?> getProfileImageUrl() async {
    await sharedPreferences.reload();
    return sharedPreferences.getString(_profileImageUrlKey);
  }

  @override
  Future<void> saveFollowersCount(int count) async {
    await sharedPreferences.setInt(_followersCountKey, count);
  }

  @override
  Future<int?> getFollowersCount() async {
    await sharedPreferences.reload();
    return sharedPreferences.getInt(_followersCountKey);
  }

  @override
  Future<void> saveFollowingCount(int count) async {
    await sharedPreferences.setInt(_followingCountKey, count);
  }

  @override
  Future<int?> getFollowingCount() async {
    await sharedPreferences.reload();
    return sharedPreferences.getInt(_followingCountKey);
  }

  @override
  Future<void> saveFriendsCount(int count) async {
    await sharedPreferences.setInt(_friendsCountKey, count);
  }

  @override
  Future<int?> getFriendsCount() async {
    await sharedPreferences.reload();
    return sharedPreferences.getInt(_friendsCountKey);
  }

  @override
  Future<void> saveIsPremium(bool isPremium) async {
    await sharedPreferences.setBool(_isPremiumKey, isPremium);
  }

  @override
  Future<bool> getIsPremium() async {
    await sharedPreferences.reload();
    return sharedPreferences.getBool(_isPremiumKey) ?? false;
  }

  @override
  Future<void> saveTier(UserTier tier) async {
    await sharedPreferences.setString(_tierKey, tier.name);
    // Backward compatibility for isPremium
    await saveIsPremium(tier.isPremium);
  }

  @override
  Future<UserTier> getTier() async {
    await sharedPreferences.reload();
    final tierStr = sharedPreferences.getString(_tierKey);
    return UserTier.fromString(tierStr);
  }

  @override
  Future<void> clearAuthData() async {
    await deleteToken();
    await deleteRefreshToken();
    await sharedPreferences.remove(_userIdKey);
    await sharedPreferences.remove(_usernameKey);
    await sharedPreferences.remove(_emailKey);
    await sharedPreferences.remove(_firstNameKey);
    await sharedPreferences.remove(_lastNameKey);
    await sharedPreferences.remove(_profileImageUrlKey);
    await sharedPreferences.remove(_followersCountKey);
    await sharedPreferences.remove(_followingCountKey);
    await sharedPreferences.remove(_friendsCountKey);
    await sharedPreferences.remove(_isPremiumKey);
    await sharedPreferences.remove(_tierKey);
  }
}
