import 'package:equatable/equatable.dart';
import '../../../domain/entities/friendship_status.dart';

enum FriendRequestType { none, sent, received }

abstract class FriendshipStatusState extends Equatable {
  const FriendshipStatusState();

  @override
  List<Object?> get props => [];
}

class FriendshipStatusInitial extends FriendshipStatusState {}

class FriendshipStatusLoading extends FriendshipStatusState {}

class FriendshipStatusLoaded extends FriendshipStatusState {
  final FriendshipStatus status;
  final FriendRequestType
  requestType; // To differentiate sent vs received when 'pending'
  final int? friendshipId; // 🔥 Friendship ID for actions

  const FriendshipStatusLoaded({
    required this.status,
    this.requestType = FriendRequestType.none,
    this.friendshipId,
  });

  @override
  List<Object?> get props => [status, requestType, friendshipId ?? 0];
}

class FriendshipStatusFailure extends FriendshipStatusState {
  final String message;

  const FriendshipStatusFailure(this.message);

  @override
  List<Object> get props => [message];
}
