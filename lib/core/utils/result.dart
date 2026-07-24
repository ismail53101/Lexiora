import 'package:lexiora/core/error/failures.dart';

/// A lightweight, dependency-free functional result type.
///
/// A [Result] is either an [Ok] carrying a success value, or an [Err] carrying
/// a [Failure]. This makes error handling explicit at every call site without
/// pulling in a heavier package like `dartz` or `fpdart`.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;
}

/// Successful result carrying a [value].
final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

/// Failed result carrying a [failure].
final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

extension ResultX<T> on Result<T> {
  /// Collapses the result into a single value by handling both branches.
  R fold<R>(
    R Function(Failure failure) onErr,
    R Function(T value) onOk,
  ) {
    final self = this;
    return switch (self) {
      Ok<T>() => onOk(self.value),
      Err<T>() => onErr(self.failure),
    };
  }

  /// The success value, or `null` when this is an [Err].
  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  /// The failure, or `null` when this is an [Ok].
  Failure? get failureOrNull => switch (this) {
        Err<T>(:final failure) => failure,
        Ok<T>() => null,
      };

  /// Transforms the success value while preserving a failure.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Ok<T>(:final value) => Ok<R>(transform(value)),
        Err<T>(:final failure) => Err<R>(failure),
      };
}
