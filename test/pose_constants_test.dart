import 'package:flutter_test/flutter_test.dart';
import 'package:biomechai/utils/pose_constants.dart';

void main() {
  group('Pose constants', () {
    test('landmark buffer holds 90 frames', () {
      expect(kLandmarkBufferSize, 90);
    });

    test('accepts landmarks at or above the confidence threshold', () {
      expect(isLandmarkReliable(0.5), isTrue);
      expect(isLandmarkReliable(0.95), isTrue);
    });

    test('rejects landmarks below the confidence threshold', () {
      expect(isLandmarkReliable(0.49), isFalse);
      expect(isLandmarkReliable(0.0), isFalse);
    });
  });
}
