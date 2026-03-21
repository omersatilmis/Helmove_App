import 'package:equatable/equatable.dart';

abstract class FollowActionEvent extends Equatable {
  const FollowActionEvent();

  @override
  List<Object?> get props => [];
}

class FollowUserEvent extends FollowActionEvent {
  final int userId;
  const FollowUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UnfollowUserEvent extends FollowActionEvent {
  final int userId;
  const UnfollowUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class BlockUserEvent extends FollowActionEvent {
  final int userId;
  const BlockUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UnblockUserEvent extends FollowActionEvent {
  final int userId;
  const UnblockUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}
