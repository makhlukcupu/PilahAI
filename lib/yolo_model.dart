import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import 'yoloPostProcess.dart';

class YoloModel {
  static final YoloModel _instance = YoloModel._internal();
  late Interpreter _interpreter;
  late List<int> _inputShape;
  late List<int> _outputShape;

  // ====== GEOMETRY STATE (PENTING) ======
  late double _scale;
  late int _padX;
  late int _padY;
  late int _srcW;
  late int _srcH;

  factory YoloModel() {
    return _instance;
  }

  YoloModel._internal();

  // =====================================
  // LOAD MODEL
  // =====================================
  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/best.tflite');

    _inputShape = _interpreter.getInputTensor(0).shape;
    _outputShape = _interpreter.getOutputTensor(0).shape;

    print('Input shape : $_inputShape');   // [1,640,640,3]
    print('Output shape: $_outputShape');  // [1,84,8400]
  }

  List<List<List<List<double>>>> preprocess(
      Uint8List imageData,
      int inputWidth,
      int inputHeight,
      ) {
    final image = img.decodeImage(imageData)!;

    _srcW = image.width;
    _srcH = image.height;

    _scale = math.min(
      inputWidth / _srcW,
      inputHeight / _srcH,
    );

    final newW = (_srcW * _scale).round();
    final newH = (_srcH * _scale).round();

    final resized = img.copyResize(
      image,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.linear,
    );

    _padX = ((inputWidth - newW) / 2).floor();
    _padY = ((inputHeight - newH) / 2).floor();

    // Canvas 640x640 (letterbox)
    final canvas = img.Image(
      width: inputWidth,
      height: inputHeight,
    );

    // Background hitam
    img.fill(canvas, color: img.ColorRgb8(0, 0, 0));

    // Tempel resized image
    img.compositeImage(
      canvas,
      resized,
      dstX: _padX,
      dstY: _padY,
    );

    // Convert ke tensor [1, H, W, 3]
    return [
      List.generate(inputHeight, (y) =>
          List.generate(inputWidth, (x) {
            final p = canvas.getPixel(x, y);
            return [
              p.r / 255.0,
              p.g / 255.0,
              p.b / 255.0,
            ];
          })
      )
    ];
  }


  // RUN YOLO + UNLETTERBOX
  Future<List<Map<String, dynamic>>> runYOLOv11Model(
      Uint8List imageBytes,
      ) async {

    //  PREPROCESS
    final inputBuffer = preprocess(imageBytes, 640, 640);

    // OUTPUT BUFFER
    final output = List.generate(
      _outputShape[0],
          (_) => List.generate(
        _outputShape[1],
            (_) => List.filled(_outputShape[2], 0.0),
      ),
    );

    // ---------- INFERENCE ----------
    _interpreter.run(inputBuffer, output);

    // ---------- POSTPROCESS ----------
    final numBoxes = _outputShape[2];       // 8400
    final numClasses = _outputShape[1] - 4; // class count

    final yoloProcessor = YoloPostProcessor(
      confThreshold: 0.6,
      nmsThreshold: 0.4,
    );

    List<Map<String, dynamic>> detections =
    yoloProcessor.processOutput(
      output,
      numBoxes,
      numClasses,
    );

    //  UNLETTERBOX (CENTER → CORNER)
    for (var det in detections) {
      final List<double> b = det['box']; // [cx, cy, w, h] in 640x640

      //  unpad + unscale (CENTER SPACE)
      double cx = (b[0] - _padX) / _scale;
      double cy = (b[1] - _padY) / _scale;
      double w  = b[2] / _scale;
      double h  = b[3] / _scale;

      // convert to corner
      double x1 = cx - w / 2;
      double y1 = cy - h / 2;
      double x2 = cx + w / 2;
      double y2 = cy + h / 2;

      //  clamp ke ukuran image asli
      x1 = x1.clamp(0.0, _srcW.toDouble());
      y1 = y1.clamp(0.0, _srcH.toDouble());
      x2 = x2.clamp(0.0, _srcW.toDouble());
      y2 = y2.clamp(0.0, _srcH.toDouble());

      det['box'] = [x1, y1, x2, y2];
    }

    return detections;
  }
}
