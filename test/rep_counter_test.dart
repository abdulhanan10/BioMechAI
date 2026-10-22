import 'package:flutter_test/flutter_test.dart';
import 'package:biomechai/services/form_validation_service.dart';

void main() {
  const exercise = 'Squat';

  bool doRep(RepCounterService counter, {required bool valid}) {
    counter.update(100, valid, 80, exercise);
    return counter.update(160, valid, 80, exercise);
  }

  group('RepCounterService form-based counting', () {
    test('counts a rep when form is valid', () {
      final counter = RepCounterService();
      final completed = doRep(counter, valid: true);
      expect(completed, isTrue);
      expect(counter.totalReps, 1);
      expect(counter.validReps, 1);
      expect(counter.rejectedReps, 0);
    });

    test('does not count a rep when form is invalid', () {
      final counter = RepCounterService();
      final completed = doRep(counter, valid: false);
      expect(completed, isFalse);
      expect(counter.totalReps, 0);
      expect(counter.rejectedReps, 1);
    });

    test('counts the next valid rep after an invalid one', () {
      final counter = RepCounterService();
      doRep(counter, valid: false);
      doRep(counter, valid: true);
      expect(counter.totalReps, 1);
      expect(counter.validReps, 1);
      expect(counter.rejectedReps, 1);
    });

    test('reset clears all counters', () {
      final counter = RepCounterService();
      doRep(counter, valid: true);
      doRep(counter, valid: false);
      counter.reset();
      expect(counter.totalReps, 0);
      expect(counter.validReps, 0);
      expect(counter.rejectedReps, 0);
    });

    test('plank is never counted as a rep', () {
      final counter = RepCounterService();
      expect(counter.update(100, true, 80, 'Plank'), isFalse);
      expect(counter.totalReps, 0);
    });
  });
}
