import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

const List<List<PoseLandmarkType>> kSkeletonPairs = [
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
  [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
  [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
  [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
  [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
  [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
  [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
  [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
  [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
  [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  [PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel],
  [PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel],
  [PoseLandmarkType.leftHeel, PoseLandmarkType.leftFootIndex],
  [PoseLandmarkType.rightHeel, PoseLandmarkType.rightFootIndex],
];

class PoseDetectionService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.base,
      mode: PoseDetectionMode.stream,
    ),
  );

  final Queue<List<Pose>> landmarkBuffer = Queue<List<Pose>>();
  final int _bufferSize = 90;

  bool _isBusy = false;
  
  int _frameCount = 0;
  DateTime? _lastFpsUpdate;
  double _currentFps = 0.0;

  double get fps => _currentFps;

  Future<List<Pose>> processFrame(CameraImage image, CameraDescription camera) async {
    if (_isBusy) return [];
    _isBusy = true;

    _updateFps();

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final InputImageRotation imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
      final InputImageFormat inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.yuv420;

      final InputImageMetadata metadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
      final poses = await _poseDetector.processImage(inputImage);

      landmarkBuffer.addLast(poses);
      if (landmarkBuffer.length > _bufferSize) {
        landmarkBuffer.removeFirst();
      }

      _isBusy = false;
      return poses;
    } catch (e) {
      _isBusy = false;
      return [];
    }
  }

  void _updateFps() {
    _frameCount++;
    final now = DateTime.now();
    if (_lastFpsUpdate == null) {
      _lastFpsUpdate = now;
      return;
    }
    final diff = now.difference(_lastFpsUpdate!).inMilliseconds;
    if (diff >= 1000) {
      _currentFps = (_frameCount * 1000) / diff;
      _frameCount = 0;
      _lastFpsUpdate = now;
    }
  }

  double? jointAngle(PoseLandmark? a, PoseLandmark? b, PoseLandmark? c) {
    if (a == null || b == null || c == null) return null;
    final double radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
    double angle = (radians * 180.0 / pi).abs();
    if (angle > 180.0) {
      angle = 360.0 - angle;
    }
    return angle;
  }

  void dispose() {
    _poseDetector.close();
  }
}
