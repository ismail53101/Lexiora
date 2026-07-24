import 'package:lexiora/core/error/exceptions.dart';
import 'package:lexiora/core/error/failures.dart';
import 'package:lexiora/core/utils/result.dart';

/// Maps a low-level [AppException] to its user-facing [Failure] counterpart.
Failure mapExceptionToFailure(AppException e) => switch (e) {
      DatabaseException() => DatabaseFailure(e.message, cause: e.cause),
      StorageException() => StorageFailure(e.message, cause: e.cause),
      PermissionException() => PermissionFailure(e.message, cause: e.cause),
      ImportException() => ImportFailure(e.message, cause: e.cause),
      PdfException() => PdfFailure(e.message, cause: e.cause),
      NotFoundException() => NotFoundFailure(e.message, cause: e.cause),
    };

/// Runs [body], converting thrown exceptions into a failed [Result].
///
/// This is the single place the data/domain boundary turns thrown errors into
/// values, so use cases can simply `return guard(() => repo.doThing())`.
Future<Result<T>> guard<T>(Future<T> Function() body) async {
  try {
    return Ok<T>(await body());
  } on AppException catch (e) {
    return Err<T>(mapExceptionToFailure(e));
  } catch (e) {
    return Err<T>(UnexpectedFailure(e.toString(), cause: e));
  }
}
