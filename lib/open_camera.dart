import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOLO Object Detection',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: CameraScreen(camera: camera),
    );
  }
}

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;
  const CameraScreen({super.key, required this.camera});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late tfl.Interpreter _interpreter;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
    _loadModel();
  }

  Future<void> _loadModel() async {
    _interpreter = await tfl.Interpreter.fromAsset('assets/yolov11n.tflite');
  }

  @override
  void dispose() {
    _controller.dispose();
    _interpreter.close();
    super.dispose();
  }

  Future<void> _captureAndDetect() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();

      // Run YOLO detection on the captured image
      List<Map<String, dynamic>> detections = await runYoloModel(image.path);

      // Navigate to the results screen with detections
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => DetectionScreen(
            imagePath: image.path,
            detections: detections,
          ),
        ),
      );
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Camera')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _captureAndDetect,
        child: Icon(Icons.camera),
      ),
    );
  }
}

class DetectionScreen extends StatelessWidget {
  final String imagePath;
  final List<Map<String, dynamic>> detections;

  DetectionScreen({required this.imagePath, required this.detections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detections')),
      body: Stack(
        children: [
          Image.file(File(imagePath)), // Display captured image
          ...detections.map((detection) {
            return Positioned(
              left: detection['boundingBox'][0], // X coordinate
              top: detection['boundingBox'][1], // Y coordinate
              child: Container(
                width: detection['boundingBox'][2], // Width
                height: detection['boundingBox'][3], // Height
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Center(
                  child: Text(
                    detection['label'],
                    style: TextStyle(
                      color: Colors.white,
                      backgroundColor: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class DetailScreen extends StatelessWidget {
  final String label;
  const DetailScreen({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail: $label')),
      body: Center(child: Text('More information about $label')),
    );
  }
}

Future<List<Map<String, dynamic>>> runYoloModel(String imagePath) async {
  final interpreter = await tfl.Interpreter.fromAsset('assets/yolov11n.tflite');

  final image = img.decodeImage(File(imagePath).readAsBytesSync());
  final resizedImage = img.copyResize(image!, width: 640, height: 640);

  final input = imageToByteListFloat32(resizedImage, 640, 127.5, 127.5);
  var output = List.filled(1 * 10 * 6, 0.0).reshape([1, 10, 6]);

  interpreter.run(input, output);
  interpreter.close();

  List<Map<String, dynamic>> detections = [];
  for (var i = 0; i < 10; i++) {
    double confidence = output[0][i][4];
    if (confidence > 0.5) {
      detections.add({
        'label': 'Object ${i + 1}',
        'boundingBox': output[0][i].sublist(0, 4),
      });
    }
  }
  return detections;
}

Uint8List imageToByteListFloat32(
    img.Image image,
    int inputSize,
    double mean,
    double std,
    ) {
  var convertedBytes = Uint8List(1 * inputSize * inputSize * 3);
  var buffer = ByteData.view(convertedBytes.buffer);
  int pixelIndex = 0;
  for (var y = 0; y < inputSize; y++) {
    for (var x = 0; x < inputSize; x++) {
      var pixel = image.getPixel(x, y);
      buffer.setFloat32(pixelIndex, (pixel.r - mean) / std, Endian.little);
      buffer.setFloat32(pixelIndex + 1, (pixel.g - mean) / std, Endian.little);
      buffer.setFloat32(pixelIndex + 2, (pixel.b - mean) / std, Endian.little);
      pixelIndex += 3;
    }
  }
  return convertedBytes;
}
