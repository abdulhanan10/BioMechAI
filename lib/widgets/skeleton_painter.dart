import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/pose_detection_service.dart';

enum SkeletonMode { detecting, valid, invalid }

class SkeletonPainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final bool isFront;
  final SkeletonMode mode;

  SkeletonPainter({
    required this.poses,
    required this.imageSize,
    required this.isFront,
    required this.mode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty) return;

    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    Color boneColor;
    switch (mode) {
      case SkeletonMode.detecting:
        boneColor = const Color(0xFF58A6FF); // blue
        break;
      case SkeletonMode.valid:
        boneColor = const Color(0xFF3FB950); // green
        break;
      case SkeletonMode.invalid:
        boneColor = const Color(0xFFF85149); // red
        break;
    }

    final Paint bonePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..color = boneColor;

    final Paint jointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    for (final pose in poses) {
      // Draw bones
      for (final pair in kSkeletonPairs) {
        final lm1 = pose.landmarks[pair[0]];
        final lm2 = pose.landmarks[pair[1]];

        if (lm1 != null && lm2 != null) {
          double x1 = lm1.x * scaleX;
          double y1 = lm1.y * scaleY;
          double x2 = lm2.x * scaleX;
          double y2 = lm2.y * scaleY;

          if (isFront) {
            x1 = size.width - x1;
            x2 = size.width - x2;
          }

          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), bonePaint);
        }
      }

      pose.landmarks.forEach((_, landmark) {
        double x = landmark.x * scaleX;
        double y = landmark.y * scaleY;

        if (isFront) {
          x = size.width - x;
        }

        canvas.drawCircle(Offset(x, y), 4.5, jointPaint);
      });
    }
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) {
    return oldDelegate.poses != poses || oldDelegate.mode != mode;
  }
}
