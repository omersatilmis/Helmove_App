import 'package:equatable/equatable.dart';

abstract class FriendshipActionState extends Equatable {
  const FriendshipActionState();

  @override
  List<Object> get props => [];
}

class FriendshipActionInitial extends FriendshipActionState {}

class FriendshipActionLoading extends FriendshipActionState {}

class FriendshipActionSuccess extends FriendshipActionState {
  final String message;
  final int? targetUserId;

  const FriendshipActionSuccess(this.message, {this.targetUserId});

  @override
  List<Object> get props => targetUserId != null ? [message, targetUserId!] : [message];
}

class FriendshipActionFailure extends FriendshipActionState {
  final String error;

  const FriendshipActionFailure(this.error);

  @override
  List<Object> get props => [error];
}
