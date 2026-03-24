import 'package:helmove/core/enums/user_tier.dart';

import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/motorcycle_entity.dart';
import '../dto/profile_response_dto.dart';
import '../dto/motorcycle_dto.dart';

/// DTO ↔ Entity dönüşüm mapper'ı
class ProfileMapper {
  /// ProfileDataDto → ProfileEntity
  static ProfileEntity toProfileEntity(ProfileDataDto dto) {
    return ProfileEntity(
      id: dto.id,
      username: dto.username,
      email: dto.email,
      firstName: dto.firstName,
      lastName: dto.lastName,
      bio: dto.bio,
      phoneNumber: dto.phoneNumber,
      address: dto.address,
      city: dto.city,
      region: dto.region,
      profileImageUrl: dto.profileImageUrl,
      shareLocation: dto.shareLocation,
      showProfileToOthers: dto.showProfileToOthers,
      latitude: dto.latitude,
      longitude: dto.longitude,
      lastSeen: dto.lastSeen,
      isOnline: dto.isOnline,
      followersCount: dto.followersCount,
      followingCount: dto.followingCount,
      friendsCount: dto.friendsCount,
      isFollowing: dto.isFollowing,
      tier: UserTier.fromString(dto.premiumTier),
      coverImageUrl: dto.coverImageUrl,
      instagramUrl: dto.instagramUrl,
      youtubeUrl: dto.youtubeUrl,
      twitterUrl: dto.twitterUrl,
    );
  }

  /// MotorcycleDto → MotorcycleEntity
  static MotorcycleEntity toMotorcycleEntity(MotorcycleDto dto) {
    return MotorcycleEntity(
      id: dto.id,
      brand: dto.brand,
      model: dto.model,
      year: dto.year,
      licensePlate: dto.licensePlate,
      color: dto.color,
      engineSize: dto.engineSize,
      description: dto.description,
      isPrimary: dto.isPrimary,
    );
  }

  /// List&lt;MotorcycleDto&gt; → List&lt;MotorcycleEntity&gt;
  static List<MotorcycleEntity> toMotorcycleEntityList(
    List<MotorcycleDto> dtos,
  ) {
    return dtos.map((dto) => toMotorcycleEntity(dto)).toList();
  }
}
