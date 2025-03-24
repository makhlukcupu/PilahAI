import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data'; // ✅ Import Uint8List
//import 'dart:convert';
//import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter_plus/tflite_flutter_plus.dart';
import 'package:tflite_flutter_helper_plus/tflite_flutter_helper_plus.dart';
import 'dart:io';
import 'package:skripshot/yoloPostProcess.dart';
//import 'dart:ui' as ui;


void main() {
  runApp(WasteSortingApp());
}

class WasteSortingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WasteSortingScreen(),
    );
  }
}

class WasteSortingScreen extends StatefulWidget {
  @override
  _WasteSortingScreenState createState() => _WasteSortingScreenState();
}

class _WasteSortingScreenState extends State<WasteSortingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  File? _image;
  final picker = ImagePicker();
  List<Map<String, dynamic>> _detections = [];
  double _imageWidth = 0;
  double _imageHeight = 0;
  late Interpreter _interpreter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadModel(); // Load the TFLite model when the app starts
  }

  // Load the TFLite model from the assets folder
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('best.tflite');
      _interpreter.allocateTensors(); // Explicitly allocate tensors
      // print("✅ TFLite model loaded and tensors allocated.");
      //

    } catch (e) {
      // print("❌ Error loading TFLite model: $e");
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _getImageDimensions(_image!);
      runModelOnImage(_image!);
    }
  }

  // Get the image dimensions
  Future<void> _getImageDimensions(File image) async {
    final decodedImage = await decodeImageFromList(image.readAsBytesSync());
    setState(() {
      _imageWidth = decodedImage.width.toDouble();
      _imageHeight = decodedImage.height.toDouble();
      //print("saya lapar" +  _imageWidth.toString());
    });
  }

  // Run object detection on the selected image
  Future<void> runModelOnImage(File imageFile) async {
    if (_interpreter == null) {
      print("❌ Interpreter is NULL. Model not loaded.");
      return;
    }
    print("📌 Model Input Shape: ${_interpreter.getInputTensor(0).shape} | Type: ${_interpreter.getInputTensor(0).type}");
    print("📌 Expected Input Type: ${_interpreter.getInputTensor(0).type}");
    print("📌 Model Output Shape: ${_interpreter.getOutputTensor(0).shape} | Type: ${_interpreter.getOutputTensor(0).type}");

    print("✅ Running model...");

    try {
      // ✅ Read Image from File
      Uint8List imageBytes = await imageFile.readAsBytes(); // Read bytes from File
      img.Image? image = img.decodeImage(imageBytes); // Decode image

      if (image == null) {
        print("❌ Error: Failed to decode image.");
        return;
      }

      // ✅ Convert Image to TensorImage
      var inputImage = TensorImage(TfLiteType.float32);
      inputImage.loadImage(image); // ✅ Now inputImage is correctly loaded

      // ✅ Print raw pixel values before preprocessing
      //print("📌 First 10 Raw Image Pixel Values: ${inputImage.getTensorBuffer().getDoubleList().sublist(0, 10)}");

      // ✅ Apply Image Processing (Resize + Normalize)
      var imageProcessor = ImageProcessorBuilder()
          .add(ResizeOp(640, 640, ResizeMethod.bilinear))  // Resize to match model input
          .add(NormalizeOp(127.5, 127.5))  // Normalize between -1 and 1
          .build();

      inputImage = imageProcessor.process(inputImage);

      // ✅ Check if Normalization Worked
      //print("📌 First 10 Normalized Tensor Values: ${inputImage.getTensorBuffer().getDoubleList().sublist(0, 10)}");

      // ✅ Convert to Float32 Buffer
      var inputBuffer = inputImage.getTensorBuffer();
      var floatBuffer = TensorBuffer.createFixedSize(inputBuffer.getShape(), TfLiteType.float32);
      floatBuffer.loadList(inputBuffer.getDoubleList(), shape: inputBuffer.getShape()); // 🔹 Fix: Pass shape explicitly

      // ✅ Print Final Processed Values
      //print("📌 First 10 Float32 Tensor Values Before Model: ${floatBuffer.getDoubleList().sublist(0, 10)}");

      // ✅ Run Inference
      var outputBuffer = TensorBuffer.createFixedSize(_interpreter.getOutputTensor(0).shape, TfLiteType.float32);
      _interpreter.run(floatBuffer.buffer, outputBuffer.buffer);

      //print("✅ Model execution finished.");


      // ✅ Extract Output Data
      List<double> outputData = outputBuffer.getDoubleList();
      //print("📌 Raw Output Data Length: ${outputData.length}");
      //print("📌 First 50 values: ${outputData.sublist(33598, 33620)}"); // Print first 50 values

      // ✅ Process YOLO Output (8400 detections)
      int numBoxes = 8400;
      int numClasses = 80; // adjust to number of classes of my model

      final yoloProcessor = YoloPostProcessor(confThreshold: 0.6, nmsThreshold: 0.4);
      List<Map<String, dynamic>> detections = yoloProcessor.processOutput(outputData, numBoxes, numClasses);

      //print("📌 Final Detections: $detections");



      setState(() {
        _detections = detections;
      });

      //print("📌 Detections: $_detections");

      // ✅ Navigate to result screen (even if no detections)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetectionResultScreen(
            image: _image!,
            recognitions: _detections!,
            imageWidth: _imageWidth,
            imageHeight: _imageHeight,
          ),
        ),
      );
    } catch (e, stacktrace) {
      print("❌ Error running model: $e");
      print(stacktrace);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SORTING GUIDE', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          indicatorColor: Colors.green,
          tabs: [
            Tab(text: 'CATEGORIES'),
            Tab(text: 'OBJECTS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          WasteCategoryGrid(),
          Center(child: Text('Objects Placeholder', style: TextStyle(fontSize: 18))),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: Icon(Icons.camera_alt),
        backgroundColor: Colors.green,
      ),
    );
  }
}

class WasteCategoryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.weekend, 'label': 'BULKY WASTE'},
    {'icon': Icons.local_shipping, 'label': 'CARTON'},
    {'icon': Icons.bolt, 'label': 'EE-WASTE'},
    {'icon': Icons.tv, 'label': 'ELECTRONIC'},
    {'icon': Icons.checkroom, 'label': 'FABRIC/CLOTHES/SHOES'},
    {'icon': Icons.science, 'label': 'FAT'},
    {'icon': Icons.wine_bar, 'label': 'GLASS'},
    {'icon': Icons.warning, 'label': 'HAZARDOUS WASTE'},
    {'icon': Icons.build, 'label': 'METAL'},
    {'icon': Icons.eco, 'label': 'ORGANIC WASTE'},
    {'icon': Icons.menu_book, 'label': 'PAPER'},
    {'icon': Icons.local_drink, 'label': 'PLASTIC'},
    {'icon': Icons.category, 'label': 'POLYSTYRENE'},
    {'icon': Icons.delete, 'label': 'RESIDUAL WASTE'},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WasteDetailScreen(label: categories[index]['label']),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(categories[index]['icon'], size: 50, color: Colors.grey[700]),
              SizedBox(height: 8),
              Text(categories[index]['label'],
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}

class WasteDetailScreen extends StatelessWidget {
  final String label;

  WasteDetailScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(label),
      ),
      body: Center(
        child: Text("Details about $label", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}

class DetectionResultScreen extends StatelessWidget {
  final File image;
  final List<Map<String, dynamic>> recognitions;
  final double imageWidth;
  final double imageHeight;

  DetectionResultScreen({
    required this.image,
    required this.recognitions,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detection Results')),
      body: Center(
        child: Stack(
          children: [
            Image.file(image),
            ...recognitions.map((detection) {
              List<double> box = detection["box"];
              double score = detection["confidence"];
              int object = detection["classIndex"];
              //print(box[0].toString() + " // " + box[1].toString() + " // " + box[2].toString() + " // " + box[3].toString());
              print(box[0] * MediaQuery.of(context).size.width);
              print(box[1] * MediaQuery.of(context).size.height);
              print((box[2]-box[0])* MediaQuery.of(context).size.width);
              print((box[3]-box[1]) * MediaQuery.of(context).size.height);
              print(MediaQuery.of(context).size.width);
              print(MediaQuery.of(context).size.height);
              return Positioned(
                left: box[0] * MediaQuery.of(context).size.width,
                top: box[1] * MediaQuery.of(context).size.height,
                width: (box[2]-box[0])* MediaQuery.of(context).size.width,
                height: (box[3]-box[1]) * MediaQuery.of(context).size.height,
                child:
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Text(object.toString() + "obj " + '${score.toStringAsFixed(2)}')
                ),

              );
            }).toList(),

          ],
        ),
      ),
    );
  }
}

