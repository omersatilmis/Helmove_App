import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure([this.message = 'Unexpected Error']);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server Failure']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache Failure']);
}
