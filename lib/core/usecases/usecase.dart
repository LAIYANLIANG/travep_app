import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

/// [UseCase] is the base interface for all business logic units.
///
/// It strictly follows the Command Pattern.
/// [Type] is the return type of the success case.
/// [Params] is the type of the parameters passed to the use case.
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// A special parameter class for UseCases that don't need any arguments.
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
