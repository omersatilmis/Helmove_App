enum GroupRole {
  admin,
  captain,
  rider;

  String get displayName {
    switch (this) {
      case GroupRole.admin:
        return 'Admin';
      case GroupRole.captain:
        return 'Captain';
      case GroupRole.rider:
        return 'Rider';
    }
  }

  static GroupRole fromString(String? role) {
    if (role == null) return GroupRole.rider;
    switch (role.toLowerCase()) {
      case 'admin':
      case '0':
        return GroupRole.admin;
      case 'captain':
      case '1':
        return GroupRole.captain;
      default:
        return GroupRole.rider;
    }
  }
}
