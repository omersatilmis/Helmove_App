import 'package:equatable/equatable.dart';

abstract class FriendshipActionEvent extends Equatable {
  const FriendshipActionEvent();

  @override
  List<Object> get props => [];
}

class SendFriendRequestEvent extends FriendshipActionEvent {
  final int targetUserId;
  final String message;

  const SendFriendRequestEvent({
    required this.targetUserId,
    required this.message,
  });

  @override
  List<Object> get props => [targetUserId, message];
}

class AcceptFriendRequestEvent extends FriendshipActionEvent {
  final int friendshipId;

  const AcceptFriendRequestEvent({required this.friendshipId});

  @override
  List<Object> get props => [friendshipId];
}

class RejectFriendRequestEvent extends FriendshipActionEvent {
  final int friendshipId;

  const RejectFriendRequestEvent({required this.friendshipId});

  @override
  List<Object> get props => [friendshipId];
}

class CancelSentRequestEvent extends FriendshipActionEvent {
  final int friendshipId;

  const CancelSentRequestEvent({required this.friendshipId});

  @override
  List<Object> get props => [friendshipId];
}

class RemoveFriendEvent extends FriendshipActionEvent {
  final int friendId;

  const RemoveFriendEvent({required this.friendId});

  @override
  List<Object> get props => [friendId];
}

class BlockUserEvent extends FriendshipActionEvent {
  final int targetUserId;

  const BlockUserEvent({required this.targetUserId});

  @override
  List<Object> get props => [targetUserId];
}

class UnblockUserEvent extends FriendshipActionEvent {
  final int targetUserId;

  const UnblockUserEvent({required this.targetUserId});

  @override
  List<Object> get props => [targetUserId];
}
