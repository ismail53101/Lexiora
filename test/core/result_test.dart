import 'package:flutter_test/flutter_test.dart';
import 'package:lexiora/core/error/failures.dart';
import 'package:lexiora/core/utils/result.dart';

void main() {
  group('Result', () {
    test('Ok holds a value and folds to the ok branch', () {
      const Result<int> r = Ok<int>(42);
      expect(r.isOk, isTrue);
      expect(r.isErr, isFalse);
      expect(r.valueOrNull, 42);
      expect(r.failureOrNull, isNull);
      expect(r.fold((_) => 'err', (int v) => 'ok $v'), 'ok 42');
    });

    test('Err holds a failure and folds to the err branch', () {
      const Result<int> r = Err<int>(DatabaseFailure('boom'));
      expect(r.isErr, isTrue);
      expect(r.valueOrNull, isNull);
      expect(r.failureOrNull, isA<DatabaseFailure>());
      expect(r.fold((Failure f) => f.message, (_) => 'ok'), 'boom');
    });

    test('map transforms an Ok and preserves an Err', () {
      expect(const Ok<int>(2).map((int v) => v * 3).valueOrNull, 6);
      expect(
        const Err<int>(DatabaseFailure('x')).map((int v) => v * 3).isErr,
        isTrue,
      );
    });
  });
}
