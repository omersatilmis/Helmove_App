import 'package:helmove/core/enums/user_tier.dart';

import '../../domain/entities/auth_entity.dart';
import '../dto/login_response_dto.dart';

class AuthMapper {
  static AuthEntity toEntity(LoginResponseDto dto) {
    if (dto.data == null) {
      throw Exception("Login data is null");
    }
    final data = dto.data!;
    return AuthEntity(
      id: data.id ?? 0,
      username: data.username ?? '',
      email: data.email ?? '',
      token: data.token,
      firstName: data.firstName,
      lastName: data.lastName,
      profileImageUrl: data.profileImageUrl,
      tier: UserTier.fromString(data.premiumTier),
    );
  }
}

extension LoginResponseDtoExtension on LoginResponseDto {
  AuthEntity toEntity() {
    return AuthMapper.toEntity(this);
  }
}
