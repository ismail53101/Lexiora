import 'package:lexiora/core/utils/result.dart';

/// A future returning a [Result] — the standard return type for use cases and
/// repository methods that can fail.
typedef ResultFuture<T> = Future<Result<T>>;

/// A [ResultFuture] with no meaningful success payload.
typedef ResultVoid = ResultFuture<void>;

/// Convenience alias for untyped JSON-like maps.
typedef DataMap = Map<String, dynamic>;
