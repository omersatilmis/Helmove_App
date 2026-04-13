import '../../../../core/enums/user_tier.dart';
import 'motorcycle_entity.dart';

/// Profil Domain Entity
class ProfileEntity {
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
  final double? latitude;
  final double? longitude;
  final DateTime? lastSeen;
  final bool isOnline;
  final int followersCount;
  final int followingCount;
  final int friendsCount;
  final UserTier tier;
  final bool isFollowing;
  final bool isFollower;
  final String? coverImageUrl;
  final String? instagramUrl;
  final String? youtubeUrl;
  final String? twitterUrl;
  final List<MotorcycleEntity> motorcycles;

  const ProfileEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.tier,
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
    this.coverImageUrl,
    this.instagramUrl,
    this.youtubeUrl,
    this.twitterUrl,
    this.motorcycles = const [],
  });

  /// Full name helper
  String get fullName {
    if (firstName == null && lastName == null) return username;
    return "${firstName ?? ''} ${lastName ?? ''}".trim();
  }

  /// Has location data
  bool get hasLocation => latitude != null && longitude != null;

  /// CopyWith for optimistic updates
  ProfileEntity copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? bio,
    String? phoneNumber,
    String? address,
    String? city,
    String? region,
    String? profileImageUrl,
    bool? shareLocation,
    bool? showProfileToOthers,
    double? latitude,
    double? longitude,
    DateTime? lastSeen,
    bool? isOnline,
    int? followersCount,
    int? followingCount,
    int? friendsCount,
    bool? isFollowing,
    bool? isFollower,
    String? coverImageUrl,
    String? instagramUrl,
    String? youtubeUrl,
    String? twitterUrl,
    UserTier? tier,
    List<MotorcycleEntity>? motorcycles,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      tier: tier ?? this.tier,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      region: region ?? this.region,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      shareLocation: shareLocation ?? this.shareLocation,
      showProfileToOthers: showProfileToOthers ?? this.showProfileToOthers,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      friendsCount: friendsCount ?? this.friendsCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollower: isFollower ?? this.isFollower,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      motorcycles: motorcycles ?? this.motorcycles,
    );
  }

  @override
  String toString() {
    return 'ProfileEntity(id: $id, username: $username, fullName: $fullName, isFollowing: $isFollowing, isFollower: $isFollower, followers: $followersCount)';
  }
}
