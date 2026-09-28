import 'package:flutter_test/flutter_test.dart';
import 'package:sakani/core/error/failures.dart';
import 'package:sakani/core/utils/result.dart';

void main() {
  group('Result Functional Type Tests', () {
    test('Success returns data and isSuccess is true', () {
      const result = Success('sakani_data');

      expect(result.isSuccess, true);
      expect(result.isFailure, false);
      expect(result.dataOrNull, 'sakani_data');
      expect(result.failureOrNull, null);

      final folded = result.fold(
        (failure) => 'failed',
        (data) => 'success: $data',
      );
      expect(folded, 'success: sakani_data');
    });

    test('FailureResult returns failure and isFailure is true', () {
      const result = FailureResult<String>(ServerFailure('خطأ سيرفر'));

      expect(result.isSuccess, false);
      expect(result.isFailure, true);
      expect(result.dataOrNull, null);
      expect(result.failureOrNull?.message, 'خطأ سيرفر');

      final folded = result.fold(
        (failure) => 'handled_failure: ${failure.message}',
        (data) => 'success: $data',
      );
      expect(folded, 'handled_failure: خطأ سيرفر');
    });
  });
}
