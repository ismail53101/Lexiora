import 'package:equatable/equatable.dart';

/// Base type for every recoverable error surfaced to the domain layer.
///
/// Failures are *values* (returned inside a [Result]) rather than thrown
/// exceptions, which keeps error handling explicit and testable. Concrete
/// subtypes describe the failure category so the presentation layer can react
/// appropriately (e.g. prompt for a permission, show a retry, etc.).
sealed class Failure extends Equatable {
  const Failure(this.message, {this.cause});

  /// Human-readable, user-safe description of what went wrong.
  final String message;

  /// The underlying error/exception, kept for logging (never shown to users).
  final Object? cause;

  @override
  List<Object?> get props => [message, cause];

  @override
  String toString() => '$runtimeType($message)';
}

/// A local database (Drift/SQLite) operation failed.
final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.cause});
}

/// Reading from or writing to the device file system failed.
final class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause});
}

/// A required runtime permission was denied by the user or the OS.
final class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.cause});
}

/// Importing / copying a picked PDF into app storage failed.
final class ImportFailure extends Failure {
  const ImportFailure(super.message, {super.cause});
}

/// Rendering, parsing, or reading a PDF document failed.
final class PdfFailure extends Failure {
  const PdfFailure(super.message, {super.cause});
}

/// A requested entity could not be found.
final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.cause});
}

/// A catch-all for unanticipated errors. Prefer a specific failure when known.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.cause});
}
