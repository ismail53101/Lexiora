/// Low-level exceptions thrown by the data layer (data sources / services).
///
/// Repositories catch these and translate them into [Failure]s so the domain
/// layer only ever deals with values, never thrown exceptions.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType($message)';
}

final class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.cause});
}

final class StorageException extends AppException {
  const StorageException(super.message, {super.cause});
}

final class PermissionException extends AppException {
  const PermissionException(super.message, {super.cause});
}

final class ImportException extends AppException {
  const ImportException(super.message, {super.cause});
}

final class PdfException extends AppException {
  const PdfException(super.message, {super.cause});
}

final class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause});
}
