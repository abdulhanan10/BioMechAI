import 'package:flutter_test/flutter_test.dart';
import 'package:biomechai/utils/feedback_messages.dart';

void main() {
  group('buildFeedback', () {
    test('praises the exercise when form is great', () {
      expect(buildFeedback('Squat', 90, []), contains('Squat'));
    });

    test('shows the first correction for good but imperfect form', () {
      expect(buildFeedback('Squat', 60, ['Shoulders uneven']), 'Shoulders uneven');
    });

    test('falls back to a generic message when good form has no errors', () {
      expect(buildFeedback('Squat', 60, []), 'Good form');
    });

    test('prefixes the correction with Fix for poor form', () {
      expect(buildFeedback('Push-Up', 30, ['Keep body straight']), 'Fix: Keep body straight');
    });

    test('asks to improve form when poor form has no specific error', () {
      expect(buildFeedback('Push-Up', 30, []), 'Improve form');
    });
  });
}
