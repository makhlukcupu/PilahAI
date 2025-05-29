import 'dart:io';
import 'package:skripshot/yoloPostProcess.dart';
// import 'package:tflite_flutter_plus/tflite_flutter_plus.dart';
// import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';


class YoloModel {
  static final YoloModel _instance = YoloModel._internal();
  late Interpreter _interpreter;
  late List<int> _inputShape;
  late List<int> _outputShape;

  factory YoloModel() {
    return _instance;
  }

  YoloModel._internal();

  Future<void> loadModel() async {
    try {
      // final options = InterpreterOptions()
      //   ..addDelegate(GpuDelegateV2()) // GPU acceleration
      //   ..threads = 4;

      _interpreter = await Interpreter.fromAsset(
        'assets/best.tflite', // Your YOLO model
      );

      _inputShape = _interpreter
          .getInputTensor(0)
          .shape;
      _outputShape = _interpreter
          .getOutputTensor(0)
          .shape;

      print('Input shape: $_inputShape'); // Expected: [1, 640, 640, 3]
      print('Output shape: $_outputShape'); // Expected: [1, 84, 8400] (YOLOv8)
      print('Input type: ${_interpreter.getInputTensor(0).type}');
      print('Output type: ${_interpreter.getOutputTensor(0).type}');
    } catch (e) {
      print('Failed to load model: $e');
    }
  }

  List<List<List<List<double>>>> preprocessImage(String imagePath) {
    // 1. Load image
    final imageBytes = File(imagePath).readAsBytesSync();
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) throw Exception('Image decoding failed');

    // Resize to 640x640
    img.Image resizedImage = img.copyResize(originalImage, width: 640, height: 640);

    // Initialize input shape [1, 640, 640, 3]


    final input = List.generate(1, (_) => // batch size
    List.generate(640, (y) =>
        List.generate(640, (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [
            pixel.r / 255.0,
            pixel.g / 255.0,
            pixel.b / 255.0,
          ];
        })));

    return input;
    }

  Future<List<Map<String, dynamic>>> runYOLOv11Model(String imagePath) async {

    // 2. Preprocess input
    final inputBuffer = preprocessImage(imagePath);

    //print(inputBuffer.shape);

    // 3. Prepare output
    final output = List.generate(
      1, // Batch size
          (_) => List.generate(
        30, // Number of values per detection
            (_) => List<double>.filled(8400, 0.0), // Number of detections
      ),
    );
    // 4. Run inference
    _interpreter.run(inputBuffer, output);
// Post-process
    //print("📌 Raw Output Data Length: ${outputData.length}");

    // ✅ Process YOLO Output (8400 detections)
    int numBoxes = _interpreter
        .getOutputTensor(0)
        .shape[2];
    int numClasses = _interpreter
        .getOutputTensor(0)
        .shape[1] - 4; // adjust to number of classes of my model

    final yoloProcessor = YoloPostProcessor(
        confThreshold: 0.6, nmsThreshold: 0.4);
    List<Map<String, dynamic>> detections = yoloProcessor.processOutput(output, numBoxes, numClasses);

    return detections;
  }





// class YoloModel {
//   static final YoloModel _instance = YoloModel
//       ._internal(); // Singleton instance
//   Interpreter? _interpreter;
//
//   factory YoloModel() {
//     return _instance;
//   }
//
//   YoloModel._internal(); // Private constructor
//
//   /// Load YOLO model once
//   Future<void> loadModel() async {
//     _interpreter ??= await Interpreter.fromAsset("best.tflite");
//   }
//
//   Future<List<Map<String, dynamic>>> runYOLOv11Model(String imagePath) async {
//     if (_interpreter == null) {
//       await loadModel(); // Ensure the model is loaded
//     }
//     // Preprocess image
//     TensorBuffer preprocessImage(String imagePath) {
//       File imageFile = File(imagePath);
//       List<int> imageBytes = imageFile.readAsBytesSync();
//       img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes));
//
//       if (image == null) {
//         throw Exception("Error decoding image");
//       }
//       var inputImage = TensorImage(TfLiteType.float32);
//       inputImage.loadImage(image); // ✅ Now inputImage is correctly loaded
//
//       // ✅ Print raw pixel values before preprocessing
//       //print("📌 First 10 Raw Image Pixel Values: ${inputImage.getTensorBuffer().getDoubleList().sublist(0, 10)}");
//
//       // ✅ Apply Image Processing (Resize + Normalize)
//       var imageProcessor = ImageProcessorBuilder()
//           .add(ResizeOp(
//           640, 640, ResizeMethod.nearestneighbour)) // Resize to match model input
//           .add(NormalizeOp(0, 255.0)) // Normalize between -1 and 1
//           .build();
//
//       inputImage = imageProcessor.process(inputImage);
//       //print("📌 First 10 processed Image Pixel Values: ${inputImage.getTensorBuffer().getDoubleList().sublist(0, 10)}");
//       var inputBuffer = inputImage.getTensorBuffer();
//       var floatBuffer = TensorBuffer.createFixedSize(
//           inputBuffer.getShape(), TfLiteType.float32);
//       floatBuffer.loadList(inputBuffer.getDoubleList(),
//           shape: inputBuffer.getShape()); // 🔹 Fix: Pass shape explicitly
//       return floatBuffer;
//     }
//     var imageTensor = preprocessImage(imagePath);
//     //print(imageTensor.getDoubleList());
//
//     // Define output buffer shape
//     var outputBuffer = TensorBuffer.createFixedSize(_interpreter!
//         .getOutputTensor(0)
//         .shape, TfLiteType.float32);
//     //print(_interpreter!.getOutputTensor(0).shape);
//
//     // Run inference
//     //print("✅ Running YOLO model...");
//     _interpreter!.run(imageTensor.buffer, outputBuffer.buffer);
//
//
//     // Post-process
//     List<double> outputData = outputBuffer.getDoubleList();
//     //print("📌 Raw Output Data Length: ${outputData.length}");
//
//     // ✅ Process YOLO Output (8400 detections)
//     int numBoxes = _interpreter!.getOutputTensor(0).shape[2];
//     int numClasses = _interpreter!.getOutputTensor(0).shape[1] - 4; // adjust to number of classes of my model
//
//     final yoloProcessor = YoloPostProcessor(
//         confThreshold: 0.6, nmsThreshold: 0.4);
//     List<Map<String, dynamic>> detections = yoloProcessor.processOutput(
//         outputData, numBoxes, numClasses);
//
//     return detections;
//   }
//   /// Close model when app exits
//   void close() {
//     _interpreter?.close();
//     _interpreter = null;
//   }
// }
//
}
