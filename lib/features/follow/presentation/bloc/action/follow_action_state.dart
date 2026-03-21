import 'package:equatable/equatable.dart';

abstract class FollowActionState extends Equatable {
  const FollowActionState();

  @override
  List<Object?> get props => [];
}

class FollowActionInitial extends FollowActionState {}

class FollowActionLoading extends FollowActionState {
  final int userId;
  const FollowActionLoading(this.userId);

  @override
  List<Object?> get props => [userId];
}

class FollowUserSuccess extends FollowActionState {
  final int userId;
  const FollowUserSuccess(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UnfollowUserSuccess extends FollowActionState {
  final int userId;
  const UnfollowUserSuccess(this.userId);

  @override
  List<Object?> get props => [userId];
}

class BlockUserSuccess extends FollowActionState {
  final int userId;
  const BlockUserSuccess(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UnblockUserSuccess extends FollowActionState {
  final int userId;
  const UnblockUserSuccess(this.userId);

  @override
  List<Object?> get props => [userId];
}

class FollowActionError extends FollowActionState {
  final String message;
  const FollowActionError(this.message);

  @override
  List<Object?> get props => [message];
}
