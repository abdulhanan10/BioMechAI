import 'package:flutter_test/flutter_test.dart';
import 'package:biomechai/utils/validators.dart';

void main() {
  group('Validators body details', () {
    test('accepts valid body details', () {
      expect(
        Validators.validateBodyDetails(height: '175', weight: '70', age: '22'),
        isNull,
      );
    });

    test('rejects empty height', () {
      expect(Validators.validateHeight(''), isNotNull);
    });

    test('rejects height out of range', () {
      expect(Validators.validateHeight('50'), isNotNull);
      expect(Validators.validateHeight('300'), isNotNull);
    });

    test('rejects weight out of range', () {
      expect(Validators.validateWeight('10'), isNotNull);
      expect(Validators.validateWeight('500'), isNotNull);
    });

    test('rejects invalid age', () {
      expect(Validators.validateAge('abc'), isNotNull);
      expect(Validators.validateAge('5'), isNotNull);
    });
  });
}
