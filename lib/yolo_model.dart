import 'dart:io';
import 'package:skripshot/yoloPostProcess.dart';
import 'package:tflite_flutter_plus/tflite_flutter_plus.dart';
import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class YoloModel {
  static final YoloModel _instance = YoloModel
      ._internal(); // Singleton instance
  Interpreter? _interpreter;

  factory YoloModel() {
    return _instance;
  }

  YoloModel._internal(); // Private constructor

  /// Load YOLO model once
  Future<void> loadModel() async {
    _interpreter ??= await Interpreter.fromAsset("best.tflite");
  }

  Future<List<Map<String, dynamic>>> runYOLOv11Model(String imagePath) async {
    if (_interpreter == null) {
      await loadModel(); // Ensure the model is loaded
    }
    // Preprocess image
    TensorBuffer preprocessImage(String imagePath) {
      File imageFile = File(imagePath);
      List<int> imageBytes = imageFile.readAsBytesSync();
      img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes));

      if (image == null) {
        throw Exception("Error decoding image");
      }
      var inputImage = TensorImage(TfLiteType.float32);
      inputImage.loadImage(image); // ✅ Now inputImage is correctly loaded

      // ✅ Print raw pixel values before preprocessing
      //print("📌 First 10 Raw Image Pixel Values: ${inputImage.getTensorBuffer().getDoubleList().sublist(0, 10)}");

      // ✅ Apply Image Processing (Resize + Normalize)
      var imageProcessor = ImageProcessorBuilder()
          .add(ResizeOp(
          640, 640, ResizeMethod.nearestneighbour)) // Resize to match model input
          .add(NormalizeOp(0, 255.0)) // Normalize between -1 and 1
          .build();

      inputImage = imageProcessor.process(inputImage);
      //print("📌 First 10 processed Image Pixel Values: ${inputImage.getTensorBuffer().getDoubleList().sublist(0, 10)}");
      var inputBuffer = inputImage.getTensorBuffer();
      var floatBuffer = TensorBuffer.createFixedSize(
          inputBuffer.getShape(), TfLiteType.float32);
      floatBuffer.loadList(inputBuffer.getDoubleList(),
          shape: inputBuffer.getShape()); // 🔹 Fix: Pass shape explicitly
      return floatBuffer;
    }
    var imageTensor = preprocessImage(imagePath);
    //print(imageTensor.getDoubleList());

    // Define output buffer shape
    var outputBuffer = TensorBuffer.createFixedSize(_interpreter!
        .getOutputTensor(0)
        .shape, TfLiteType.float32);
    //print(_interpreter!.getOutputTensor(0).shape);

    // Run inference
    //print("✅ Running YOLO model...");
    _interpreter!.run(imageTensor.buffer, outputBuffer.buffer);


    // Post-process
    List<double> outputData = outputBuffer.getDoubleList();
    //print("📌 Raw Output Data Length: ${outputData.length}");

    // ✅ Process YOLO Output (8400 detections)
    int numBoxes = _interpreter!.getOutputTensor(0).shape[2];
    int numClasses = _interpreter!.getOutputTensor(0).shape[1] - 4; // adjust to number of classes of my model

    final yoloProcessor = YoloPostProcessor(
        confThreshold: 0.4, nmsThreshold: 0.4);
    List<Map<String, dynamic>> detections = yoloProcessor.processOutput(
        outputData, numBoxes, numClasses);

    return detections;
  }
  /// Close model when app exits
  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}

