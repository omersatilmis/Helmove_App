import 'package:equatable/equatable.dart';
import '../../../domain/entities/follow_user.dart';

abstract class FollowListState extends Equatable {
  const FollowListState();

  @override
  List<Object?> get props => [];
}

class FollowListInitial extends FollowListState {}

class FollowListLoading extends FollowListState {}

class FollowListLoaded extends FollowListState {
  final List<FollowUser> users;
  final bool hasReachedMax;

  const FollowListLoaded({
    required this.users,
    this.hasReachedMax = false,
  });

  FollowListLoaded copyWith({
    List<FollowUser>? users,
    bool? hasReachedMax,
  }) {
    return FollowListLoaded(
      users: users ?? this.users,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [users, hasReachedMax];
}

class FollowListError extends FollowListState {
  final String message;

  const FollowListError(this.message);

  @override
  List<Object?> get props => [message];
}
