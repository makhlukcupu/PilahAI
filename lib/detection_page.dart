import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:skripshot/main.dart';
import 'yolo_model.dart';
import 'package:skripshot/models.dart';
import 'data_loader.dart';
import 'package:skripshot/waste_detail_page.dart';
import 'package:skripshot/search_page.dart';
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
    await _getImageSize();
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
      await loadLabels();
    }
    if (objectMap.isEmpty){
      await loadObjectMapping();
    }
    try {
      List<Map<String, dynamic>> results = await model.runYOLOv11Model(widget.imagePath);
      if (!mounted) return;

      setState(() {
        detectedBoxes = results;
        isProcessing = false;
      });
    } catch (e) {
      print("gagal dijalankan");
      print(e);
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hasil scan")),
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
                Positioned.fill(
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
                  child:
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Tidak ada objek terdeteksi",
                        style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AllObjectsPage()));
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search, color: Colors.black87),
                              SizedBox(width: 8),
                              Text(
                                "Cari secara manual",
                                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ..._drawBoundingBoxes(),
              Positioned.fill(
                child: DetectionBottomDrawer(
                  objects: detectedBoxes
                      .map((d) => objectMap[d['classIndex']])
                      .whereType<WasteObject>()
                      .toList(),
                  onTapObject: (object) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ObjectDetailPage(object: object, icon: WasteRepository.categories.firstWhere((o) => o.id == object.categoryId).icon ,)),
                    );
                  },
                  onManualSearch: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AllObjectsPage()),
                  ),
                ),
              ),
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
      WasteObject? object = objectMap[detection['classIndex']];

      double x = box[0] * displayWidth + offsetX;
      double y = box[1] * displayHeight + offsetY;
      double width = (box[2] - box[0]) * displayWidth;
      double height = (box[3] - box[1]) * displayHeight;

      return Stack(
        children: [
          // Bounding Box
          Positioned(
            left: x,
            top: y,
            width: width,
            height: height,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
              ),
            ),
          ),
          // Label Positioned Above the Box
          Positioned(
            left: x,
            top: y - 30, // Move the label above the box
            child: GestureDetector(
              onTap: () {
                //_navigateToDetail(classLabels[object]!);

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ObjectDetailPage(object: object, icon: WasteRepository.categories.firstWhere((o) => o.id == object.categoryId).icon ,)),
                );

              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(200), // Replace withAlpha instead of withOpacity
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  "${object!.name} ${score.toStringAsFixed(2)}",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

}

class DetectionBottomDrawer extends StatefulWidget {
  final List<WasteObject> objects;
  final Function(WasteObject) onTapObject;
  final VoidCallback? onManualSearch;

  const DetectionBottomDrawer({
    Key? key,
    required this.objects,
    required this.onTapObject,
    required this.onManualSearch
  }) : super(key: key);

  @override
  _DetectionBottomDrawerState createState() => _DetectionBottomDrawerState();
}

class _DetectionBottomDrawerState extends State<DetectionBottomDrawer> {
  late DraggableScrollableController _controller;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController();
  }

  void _toggleDrawer() {
    final targetSize = isExpanded ? 0.08 : 0.4;
    _controller.animateTo(
      targetSize,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: 0.08,
      minChildSize: 0.08,
      maxChildSize: 0.4,
      builder: (context, scrollController) {
        return GestureDetector(
          onTap: _toggleDrawer,
          behavior: HitTestBehavior.opaque,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
            ),
            child: ListView(
              controller: scrollController,
              physics: BouncingScrollPhysics(),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Center(
                  child: Text("Objek Terdeteksi", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 12),
                ...widget.objects.map((obj) => ListTile(
                  title: Text(obj.name),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => widget.onTapObject(obj),
                )),
                ListTile(
                  leading: Icon(Icons.search, color: Colors.grey[800]),
                  title: Text(
                    "Sampahmu tidak terdeteksi?",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text("Coba cari secara manual"),
                  onTap: () {
                    if (widget.onManualSearch != null) {
                      widget.onManualSearch!();
                    } else {
                      // Default fallback (optional)
                      Navigator.pushNamed(context, '/search');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
