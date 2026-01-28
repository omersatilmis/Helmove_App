import 'package:equatable/equatable.dart';

abstract class DiscoverEvent extends Equatable {
  const DiscoverEvent();

  @override
  List<Object> get props => [];
}

class SearchUsersEvent extends DiscoverEvent {
  final String query;
  final String? city;

  const SearchUsersEvent({required this.query, this.city});

  @override
  List<Object> get props => [query, city ?? ''];
}
