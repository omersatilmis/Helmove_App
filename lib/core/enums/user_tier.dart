enum UserTier {
  free('Free', 0),
  plus('Plus', 1),
  pro('Pro', 2);

  final String name;
  final int level;
  const UserTier(this.name, this.level);

  int get tierIndex => level;

  static UserTier fromString(String? value) {
    if (value == null) return UserTier.free;
    return UserTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UserTier.free,
    );
  }

  static UserTier fromIndex(int? value) {
    return switch (value) {
      2 => UserTier.pro,
      1 => UserTier.plus,
      _ => UserTier.free,
    };
  }

  static UserTier fromJson({String? tier, int? tierIndex}) {
    if (tierIndex != null) return UserTier.fromIndex(tierIndex);
    return UserTier.fromString(tier);
  }

  /// Checks if the current tier meets or exceeds the [required] tierIndex.
  bool hasTierIndex(int requiredTierIndex) => tierIndex >= requiredTierIndex;

  /// Checks if the current tier meets or exceeds the [required] tierIndex.
  bool meets(UserTier required) => hasTierIndex(required.tierIndex);

  bool get isPremium => hasTierIndex(1);
  bool get isPlus => hasTierIndex(1);
  bool get isPro => hasTierIndex(2);
}
