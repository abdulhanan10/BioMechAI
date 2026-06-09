import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  
  List<dynamic>? _frames;
  int _currentFrame = 0;
  bool _isPlaying = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl.contains('.json')) {
      _loadMotionData();
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          setState(() {});
          _controller!.play();
        });
    }
  }

  Future<void> _loadMotionData() async {
    try {
      final request = await HttpClient().getUrl(Uri.parse(widget.videoUrl));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (!mounted) return;
      setState(() {
        _frames = jsonDecode(body);
        _isPlaying = true;
      });
      _startMotionTimer();
    } catch(e) {
      debugPrint("Error loading motion: $e");
    }
  }
  
  void _startMotionTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (_frames != null && _frames!.isNotEmpty) {
        if (mounted) {
          setState(() {
            _currentFrame = (_currentFrame + 1) % _frames!.length;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isJson = widget.videoUrl.contains('.json');
    
    return Scaffold(
      appBar: AppBar(title: Text(isJson ? 'AI Motion Replay' : 'Session Video')),
      body: Center(
        child: isJson
            ? (_frames == null 
                ? const CircularProgressIndicator() 
                : CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: _MotionPainter(_frames![_currentFrame]),
                  ))
            : (_controller != null && _controller!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  )
                : const CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (isJson) {
              _isPlaying = !_isPlaying;
              if (_isPlaying) {
                _startMotionTimer();
              } else {
                _timer?.cancel();
              }
            } else {
              if (_controller != null) {
                _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
              }
            }
          });
        },
        child: Icon(
          isJson 
            ? (_isPlaying ? Icons.pause : Icons.play_arrow)
            : ((_controller?.value.isPlaying ?? false) ? Icons.pause : Icons.play_arrow),
        ),
      ),
    );
  }
}

class _MotionPainter extends CustomPainter {
  final Map<String, dynamic> frame;
  _MotionPainter(this.frame);

  @override
  void paint(Canvas canvas, Size size) {
    final landmarks = frame['landmarks'] as Map<String, dynamic>;
    if (landmarks.isEmpty) return;

    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    
    for (var lm in landmarks.values) {
      double x = (lm['x'] as num).toDouble();
      double y = (lm['y'] as num).toDouble();
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }

    double scaleX = size.width / ((maxX - minX) == 0 ? 1 : (maxX - minX));
    double scaleY = size.height / ((maxY - minY) == 0 ? 1 : (maxY - minY));
    double scale = (scaleX < scaleY ? scaleX : scaleY) * 0.8;
    
    double offsetX = (size.width - (maxX - minX) * scale) / 2 - minX * scale;
    double offsetY = (size.height - (maxY - minY) * scale) / 2 - minY * scale;

    final paintLine = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()..color = Colors.white;

    const connections = [
      ['leftShoulder', 'rightShoulder'],
      ['leftShoulder', 'leftElbow'],
      ['leftElbow', 'leftWrist'],
      ['rightShoulder', 'rightElbow'],
      ['rightElbow', 'rightWrist'],
      ['leftShoulder', 'leftHip'],
      ['rightShoulder', 'rightHip'],
      ['leftHip', 'rightHip'],
      ['leftHip', 'leftKnee'],
      ['leftKnee', 'leftAnkle'],
      ['rightHip', 'rightKnee'],
      ['rightKnee', 'rightAnkle']
    ];

    for (var conn in connections) {
      final p1 = landmarks[conn[0]];
      final p2 = landmarks[conn[1]];
      if (p1 != null && p2 != null) {
        canvas.drawLine(
          Offset((p1['x'] as num).toDouble() * scale + offsetX, (p1['y'] as num).toDouble() * scale + offsetY),
          Offset((p2['x'] as num).toDouble() * scale + offsetX, (p2['y'] as num).toDouble() * scale + offsetY),
          paintLine,
        );
      }
    }

    for (var lm in landmarks.values) {
      canvas.drawCircle(
        Offset((lm['x'] as num).toDouble() * scale + offsetX, (lm['y'] as num).toDouble() * scale + offsetY),
        5,
        paintDot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
