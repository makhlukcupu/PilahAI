import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'detection_page.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.high);
    await _controller!.initialize();
    if (!mounted) return;
    setState(() {
      _isCameraReady = true;
    });
  }

  Future<void> _captureImage() async {
    if (!_controller!.value.isTakingPicture) {
      XFile file = await _controller!.takePicture();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetectionScreen(imagePath: file.path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isCameraReady
            ? AspectRatio(
          aspectRatio: 9 / 16, // Ensuring 9:16 ratio
          child: CameraPreview(_controller!),
        )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _captureImage,
        child: const Icon(Icons.camera),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
