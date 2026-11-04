import 'package:equatable/equatable.dart';

/// [Failure] is the base class for all errors in the Domain Layer.
/// It enforces value equality, making it easier to test error states.
abstract class Failure extends Equatable {
  final String message;
  final List<dynamic> properties;

  const Failure([this.message = '', this.properties = const <dynamic>[]]);

  @override
  List<Object> get props => [message, ...properties];
}

/// General Server Failure
class ServerFailure extends Failure {
  const ServerFailure([super.message]);
}

/// Cache Failure
class CacheFailure extends Failure {
  const CacheFailure([super.message]);
}
