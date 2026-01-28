import 'package:equatable/equatable.dart';
import '../../../friendship/domain/entities/friend_user_entity.dart';

abstract class DiscoverState extends Equatable {
  const DiscoverState();

  @override
  List<Object> get props => [];
}

class DiscoverInitial extends DiscoverState {}

class DiscoverLoading extends DiscoverState {}

class DiscoverLoaded extends DiscoverState {
  final List<FriendUserEntity> results;

  const DiscoverLoaded(this.results);

  @override
  List<Object> get props => [results];
}

class DiscoverFailure extends DiscoverState {
  final String message;

  const DiscoverFailure(this.message);

  @override
  List<Object> get props => [message];
}
