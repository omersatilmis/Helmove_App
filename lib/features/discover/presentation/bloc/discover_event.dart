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

class LoadDiscoveryContent extends DiscoverEvent {
  final bool isRefresh;
  const LoadDiscoveryContent({this.isRefresh = false});

  @override
  List<Object> get props => [isRefresh];
}
