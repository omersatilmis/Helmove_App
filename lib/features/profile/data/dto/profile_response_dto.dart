import 'package:helmove/core/network/network_module.dart';
import 'motorcycle_dto.dart';

/// Profile API response DTO
class ProfileResponseDto {
  final bool success;
  final String? message;
  final ProfileDataDto? data;

  ProfileResponseDto({required this.success, this.message, this.data});

  factory ProfileResponseDto.fromJson(Map<String, dynamic> json) {
    final dynamic dataNode = json['data'];
    final bool looksLikeProfilePayload =
        json.containsKey('userId') ||
        json.containsKey('UserId') ||
        json.containsKey('id') ||
        json.containsKey('Id') ||
        json.containsKey('username') ||
        json.containsKey('email');

    return ProfileResponseDto(
      success: json['success'] ?? true,
      message: json['message'],
      data: dataNode is Map<String, dynamic>
          ? ProfileDataDto.fromJson(dataNode)
          : (dataNode is Map
              ? ProfileDataDto.fromJson(Map<String, dynamic>.from(dataNode))
              : (looksLikeProfilePayload ? ProfileDataDto.fromJson(json) : null)),
    );
  }
}

class ProfileDataDto {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? bio;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final String? region;
  final String? profileImageUrl;
  final bool shareLocation;
  final bool showProfileToOthers;
  final String? coverImageUrl;
  final String? instagramUrl;
  final String? youtubeUrl;
  final String? twitterUrl;
  final double? latitude;
  final double? longitude;
  final DateTime? lastSeen;
  final bool isOnline;
  final int followersCount;
  final int followingCount;
  final int friendsCount;
  final bool isFollowing;
  final bool isFollower;
  final String? premiumTier;
  final List<MotorcycleDto> motorcycles;

  ProfileDataDto({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.bio,
    this.phoneNumber,
    this.address,
    this.city,
    this.region,
    this.profileImageUrl,
    this.shareLocation = false,
    this.showProfileToOthers = true,
    this.latitude,
    this.longitude,
    this.lastSeen,
    this.isOnline = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.friendsCount = 0,
    this.isFollowing = false,
    this.isFollower = false,
    this.premiumTier,
    this.coverImageUrl,
    this.instagramUrl,
    this.youtubeUrl,
    this.twitterUrl,
    this.motorcycles = const [],
  });

  factory ProfileDataDto.fromJson(Map<String, dynamic> json) {
    dynamic pickValue(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key)) {
          return json[key];
        }
      }

      for (final entry in json.entries) {
        for (final key in keys) {
          if (entry.key.toLowerCase() == key.toLowerCase()) {
            return entry.value;
          }
        }
      }

      return null;
    }

    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is List) return value.length;
      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        return toInt(
          map['count'] ??
              map['Count'] ??
              map['total'] ??
              map['Total'] ??
              map['length'] ??
              map['Length'] ??
              map['value'] ??
              map['Value'],
        );
      }
      return int.tryParse(value.toString());
    }

    bool? toBool(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is num) return value != 0;
      final normalized = value.toString().trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
      return null;
    }

    List<MotorcycleDto> parseMotorcycles(dynamic value) {
      if (value == null) return const [];

      List<dynamic>? items;
      if (value is List) {
        items = value;
      } else if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        final nested =
            map['data'] ??
            map['Data'] ??
            map['items'] ??
            map['Items'] ??
            map['motorcycles'] ??
            map['Motorcycles'];
        if (nested is List) {
          items = nested;
        }
      }

      if (items == null) return const [];

      return items
          .whereType<Map>()
          .map(
            (e) => MotorcycleDto.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    }

    return ProfileDataDto(
      id: toInt(json['userId'] ?? json['UserId'] ?? json['id'] ?? json['Id']) ?? 0,
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      bio: json['bio']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      region: json['region']?.toString(),
      profileImageUrl: NetworkModule.resolveImageUrl(
        (json['profileImageUrl'] ?? json['profilePictureUrl'])?.toString(),
      ),
      shareLocation: json['shareLocation'] ?? false,
      showProfileToOthers: json['showProfileToOthers'] ?? true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
      isOnline: json['isOnline'] ?? false,
      followersCount: toInt(
            pickValue([
              'followersCount',
              'FollowersCount',
              'followers_count',
              'Followers',
              'followers',
              'followerCount',
              'FollowerCount',
              'followersTotal',
              'FollowersTotal',
            ]),
          ) ??
          0,
      followingCount: toInt(
            pickValue([
              'followingCount',
              'FollowingCount',
              'following_count',
              'followingsCount',
              'FollowingsCount',
              'followings_count',
              'Following',
              'following',
              'followingTotal',
              'FollowingTotal',
            ]),
          ) ??
          0,
      friendsCount: toInt(json['friendsCount'] ?? json['FriendsCount']) ?? 0,
      motorcycles: parseMotorcycles(
        pickValue([
          'motorcycles',
          'Motorcycles',
        ]),
      ),
      isFollowing: toBool(
            pickValue([
              'isFollowing',
              'IsFollowing',
              'isFollowedByCurrentUser',
              'IsFollowedByCurrentUser',
              'followedByMe',
              'FollowedByMe',
            ]),
          ) ??
          false,
      isFollower: toBool(
            pickValue([
              'isFollower',
              'IsFollower',
              'followsMe',
              'FollowsMe',
            ]),
          ) ??
          false,
      premiumTier: (json['premiumTier'] ?? json['PremiumTier'])?.toString(),
      coverImageUrl: NetworkModule.resolveImageUrl(
        (json['coverImageUrl'] ?? json['CoverImageUrl'])?.toString(),
      ),
      instagramUrl: (json['instagramHandle'] ?? json['instagramUrl'] ?? json['InstagramUrl'])?.toString(),
      youtubeUrl: (json['youtubeHandle'] ?? json['youtubeUrl'] ?? json['YoutubeUrl'])?.toString(),
      twitterUrl: (json['twitterHandle'] ?? json['twitterUrl'] ?? json['TwitterUrl'])?.toString(),
    );
  }
}
