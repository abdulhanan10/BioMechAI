import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';

class VideoRecordingService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  CameraController? _cameraController;

  Future<bool> startRecording(CameraController controller, {void Function(CameraImage)? onAvailable}) async {
    if (controller.value.isRecordingVideo) return true;
    _cameraController = controller;
    
    try {
      await _cameraController!.startVideoRecording(onAvailable: onAvailable);
      return true;
    } on CameraException catch (e) {
      print('Error starting video recording: $e');
      return false;
    }
  }

  Future<String?> stopRecording() async {
    if (_cameraController == null || !_cameraController!.value.isRecordingVideo) {
      return null;
    }

    try {
      XFile file = await _cameraController!.stopVideoRecording();
      return file.path;
    } on CameraException catch (e) {
      print('Error stopping video recording: $e');
      return null;
    }
  }

  Future<String?> uploadToFirebase(String filePath, String sessionId, String userId) async {
    try {
      File file = File(filePath);
      if (!await file.exists()) return null;

      String storagePath = 'videos/$userId/$sessionId.mp4';
      Reference ref = _storage.ref().child(storagePath);
      
      UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'video/mp4'),
      );
      
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading video: $e');
      return null;
    }
  }
}
