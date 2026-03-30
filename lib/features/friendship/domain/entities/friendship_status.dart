/// Arkadaslik durumu
enum FriendshipStatus { pending, accepted, declined, blocked, none }

/// Helper to parse string to enum
FriendshipStatus friendshipStatusFromString(String? status) {
  final lowerStatus = (status ?? '').toLowerCase().trim();

  if (lowerStatus.isEmpty || lowerStatus == 'none' || lowerStatus == 'null') {
    return FriendshipStatus.none;
  }

  // Pending states with direction
  if (lowerStatus.contains('pending') ||
      lowerStatus.contains('waiting') ||
      lowerStatus.contains('sent') ||
      lowerStatus.contains('received') ||
      lowerStatus == '0' ||
      lowerStatus == '1') {
    return FriendshipStatus.pending;
  }

  if (lowerStatus.contains('accepted') ||
      lowerStatus.contains('friends') ||
      lowerStatus.contains('arkadas') ||
      lowerStatus == '2') {
    return FriendshipStatus.accepted;
  }

  if (lowerStatus.contains('declined') ||
      lowerStatus.contains('rejected') ||
      lowerStatus == '4') {
    return FriendshipStatus.declined;
  }

  if (lowerStatus.contains('blocked') || lowerStatus == '5') {
    return FriendshipStatus.blocked;
  }

  return FriendshipStatus.none;
}
