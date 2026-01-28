import 'package:equatable/equatable.dart';

abstract class FriendshipStatusEvent extends Equatable {
  const FriendshipStatusEvent();

  @override
  List<Object> get props => [];
}

class CheckFriendshipStatusEvent extends FriendshipStatusEvent {
  final int targetUserId;

  const CheckFriendshipStatusEvent({required this.targetUserId});

  @override
  List<Object> get props => [targetUserId];
}
