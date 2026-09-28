import 'package:equatable/equatable.dart';
import 'package:sakani/core/utils/result.dart';

/// Base UseCase contract.
/// All business logic interactors in the domain layer implement this.
abstract class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Helper class for use cases that do not accept parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
