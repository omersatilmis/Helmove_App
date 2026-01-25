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

  const FriendshipActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class FriendshipActionFailure extends FriendshipActionState {
  final String error;

  const FriendshipActionFailure(this.error);

  @override
  List<Object> get props => [error];
}
