import 'package:helmove/core/enums/user_tier.dart';

class AuthEntity {
  final int id;
  final String username;
  final String email;
  final String token; // API isteklerinde kullanacağımız anahtar
  final String? firstName;
  final String? lastName;
  final String? profileImageUrl; // İleride lazım olur diye ekledim
  final UserTier tier;

  const AuthEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.token,
    this.firstName,
    this.lastName,
    this.profileImageUrl,
    this.tier = UserTier.free,
  });

  bool get isPremium => tier.isPremium;

  // 🔥 SENIOR DOKUNUŞU: Helper Getter
  // UI'da "Ali Veli" yazdırmak için her seferinde string birleştirmekle uğraşma.
  // user.fullName demen yeterli olsun.
  String get fullName {
    if (firstName == null && lastName == null) return username;
    return "${firstName ?? ''} ${lastName ?? ''}".trim();
  }

  // Debug yaparken print(user) dediğinde güzel görünsün diye
  @override
  String toString() {
    return 'AuthEntity(username: $username, email: $email, token: ${token.substring(0, 5)}...)';
  }
}
