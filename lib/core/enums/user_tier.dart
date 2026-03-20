enum UserTier {
  free('Free', 0),
  plus('Plus', 1),
  pro('Pro', 2);

  final String name;
  final int level;
  const UserTier(this.name, this.level);

  static UserTier fromString(String? value) {
    if (value == null) return UserTier.free;
    return UserTier.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UserTier.free,
    );
  }

  /// Checks if the current tier meets or exceeds the [required] tier level.
  bool meets(UserTier required) => level >= required.level;

  bool get isPremium => level >= plus.level;
  bool get isPlus => meets(UserTier.plus);
  bool get isPro => meets(UserTier.pro);
}