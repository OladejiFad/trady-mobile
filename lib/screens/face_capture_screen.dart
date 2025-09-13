import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p; // ✅ avoid name conflict

class FaceCaptureScreen extends StatefulWidget {
  final Function(File faceImageFile) onImageCaptured;
  final List<CameraDescription> cameras;

  const FaceCaptureScreen({
    required this.onImageCaptured,
    required this.cameras,
    Key? key,
  }) : super(key: key);

  @override
  _FaceCaptureScreenState createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  late CameraController _controller;
  bool _isCameraInitialized = false;
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final frontCam = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
    );
    _controller = CameraController(frontCam, ResolutionPreset.medium);
    await _controller.initialize();
    setState(() => _isCameraInitialized = true);
  }

  Future<void> _captureImage() async {
    final directory = await getTemporaryDirectory();
    final imagePath = p.join(directory.path, '${DateTime.now()}.png'); // ✅ use p.join
    final image = await _controller.takePicture();
    final file = File(image.path);
    setState(() => _capturedImage = file);
    widget.onImageCaptured(file); // send back to registration form
    Navigator.pop(context); // ✅ no conflict with BuildContext
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Take Face Photo")),
      body: Column(
        children: [
          Expanded(child: CameraPreview(_controller)),
          ElevatedButton.icon(
            onPressed: _captureImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text("Capture"),
          ),
        ],
      ),
    );
  }
}
