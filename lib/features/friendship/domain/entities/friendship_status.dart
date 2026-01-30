/// Arkadaşlık durumu
enum FriendshipStatus { pending, accepted, declined, blocked, none }

/// Helper to parse string to enum
FriendshipStatus friendshipStatusFromString(String? status) {
  final lowerStatus = (status ?? '').toLowerCase().trim();

  if (lowerStatus == 'none' ||
      lowerStatus == 'null' ||
      lowerStatus == '' ||
      lowerStatus == '3') {
    return FriendshipStatus.none;
  }

  if (lowerStatus.contains('pending') ||
      lowerStatus.contains('waiting') ||
      lowerStatus == '0' ||
      lowerStatus == '1') {
    // 🔥 Hem 0, hem 1'i "Beklemede" kabul edelim
    return FriendshipStatus.pending;
  } else if (lowerStatus.contains('accepted') ||
      lowerStatus.contains('friends') ||
      lowerStatus.contains('arkadaş') ||
      lowerStatus == '2') {
    // 🔥 If 1 is pending, 2 is accepted
    return FriendshipStatus.accepted;
  } else if (lowerStatus.contains('declined') ||
      lowerStatus.contains('rejected') ||
      lowerStatus == '4') {
    return FriendshipStatus.declined;
  } else if (lowerStatus.contains('blocked') || lowerStatus == '5') {
    return FriendshipStatus.blocked;
  }

  // Fallback for explicit old system codes
  if (lowerStatus == 'accepted_old_compat') {
    return FriendshipStatus.accepted;
  }

  // Fallback: Eski sistemde 1 accepted ise ona da destek verelim
  if (lowerStatus == 'accepted_old_compat' || lowerStatus == '1_old') {
    return FriendshipStatus.accepted;
  }

  return FriendshipStatus.none;
}
