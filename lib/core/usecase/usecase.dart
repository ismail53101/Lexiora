import 'package:lexiora/core/utils/typedefs.dart';

/// Contract for a single, atomic piece of business logic.
///
/// Use cases are the only entry point the presentation layer uses to reach the
/// domain. They depend on repository *interfaces*, never on implementations,
/// keeping the dependency rule pointing inward (SOLID / Clean Architecture).
abstract interface class UseCase<T, Params> {
  ResultFuture<T> call(Params params);
}

/// Contract for a use case that exposes a reactive stream (e.g. a Drift
/// `watch` query) rather than a one-shot future.
abstract interface class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

/// Marker for use cases that take no parameters.
final class NoParams {
  const NoParams();
}
