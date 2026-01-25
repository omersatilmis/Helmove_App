/// Arkadaşlık durumu
enum FriendshipStatus { pending, accepted, declined, blocked, none }

/// Helper to parse string to enum
FriendshipStatus friendshipStatusFromString(String? status) {
  if (status == null) return FriendshipStatus.none;
  switch (status.toLowerCase()) {
    case 'pending':
    case 'waiting':
      return FriendshipStatus.pending;
    case 'accepted':
    case 'friends':
      return FriendshipStatus.accepted;
    case 'declined':
    case 'rejected':
      return FriendshipStatus.declined;
    case 'blocked':
      return FriendshipStatus.blocked;
    default:
      return FriendshipStatus.none;
  }
}
