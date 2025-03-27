import 'dart:io';
import 'package:flutter/material.dart';
import 'package:skripshot/main.dart';
import 'yolo_model.dart';


class DetectionScreen extends StatefulWidget {
  final String imagePath;
  const DetectionScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  _DetectionScreenState createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  List<Map<String, dynamic>> detectedBoxes = [];
  YoloModel model = YoloModel();
  double imageWidth = 1, imageHeight = 1;
  double displayWidth = 1, displayHeight = 1;
  double offsetX = 0, offsetY = 0;
  bool isProcessing = true;

  @override
  void initState() {
    super.initState();
    _initializeDetection();
  }

  Future<void> _initializeDetection() async {
    await _getImageSize(); // Ensure image dimensions are available
    _runObjectDetection();
  }


  Future<void> _getImageSize() async {
    final image = await decodeImageFromList(File(widget.imagePath).readAsBytesSync());
    if (mounted) {
      setState(() {
        imageWidth = image.width.toDouble();
        imageHeight = image.height.toDouble();
      });
    }
  }

  Future<void> _runObjectDetection() async {
    if (classLabels.isEmpty) {
      await loadLabels(); // Ensure labels are loaded
    }
    try {
      List<Map<String, dynamic>> results = await model.runYOLOv11Model(widget.imagePath);
      if (!mounted) return;

      setState(() {
        detectedBoxes = results;
        isProcessing = false;
      });
    } catch (e) {
      //print("Error running detection: $e");
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double screenHeight = constraints.maxHeight;
          double aspectRatio = imageWidth / imageHeight;
          double displayAspectRatio = screenWidth / screenHeight;

          if (aspectRatio > displayAspectRatio) {
            displayHeight = screenWidth / aspectRatio;
            displayWidth = screenWidth;
            offsetY = (screenHeight - displayHeight) / 2;
            offsetX = 0;
          } else {
            displayWidth = screenHeight * aspectRatio;
            displayHeight = screenHeight;
            offsetX = (screenWidth - displayWidth) / 2;
            offsetY = 0;
          }

          return Stack(
            children: [
              Center(
                child: SizedBox(
                  width: displayWidth,
                  height: displayHeight,
                  child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
                ),
              ),
              if (isProcessing)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Processing...", style: TextStyle(fontSize: 20, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              if (!isProcessing && detectedBoxes.isEmpty)
                Center(
                  child: Text(
                    "No objects detected",
                    style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ..._drawBoundingBoxes(),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _drawBoundingBoxes() {
    return detectedBoxes.map((detection) {
      List<double> box = detection["box"];
      double score = detection["confidence"];
      int object = detection["classIndex"];

      double x = box[0] * displayWidth + offsetX;
      double y = box[1] * displayHeight + offsetY;
      double width = (box[2] - box[0]) * displayWidth;
      double height = (box[3] - box[1]) * displayHeight;

      return Positioned(
        left: x,
        top: y,
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 2),
          ),

          child: Text("${classLabels[object]!} $score")
        ),
      );
    }).toList();
  }
}
