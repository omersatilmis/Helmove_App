import 'package:equatable/equatable.dart';

abstract class FollowListEvent extends Equatable {
  const FollowListEvent();

  @override
  List<Object?> get props => [];
}

class LoadFollowersEvent extends FollowListEvent {
  final int userId;
  final bool refresh;

  const LoadFollowersEvent({required this.userId, this.refresh = false});

  @override
  List<Object?> get props => [userId, refresh];
}

class LoadFollowingEvent extends FollowListEvent {
  final int userId;
  final bool refresh;

  const LoadFollowingEvent({required this.userId, this.refresh = false});

  @override
  List<Object?> get props => [userId, refresh];
}

class UpdateUserFollowStatusEvent extends FollowListEvent {
  final int userId;
  final bool isFollowing;

  const UpdateUserFollowStatusEvent({
    required this.userId,
    required this.isFollowing,
  });

  @override
  List<Object?> get props => [userId, isFollowing];
}
class LoadBlockedUsersEvent extends FollowListEvent {
  final bool refresh;

  const LoadBlockedUsersEvent({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}
