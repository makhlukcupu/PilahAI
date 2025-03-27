import 'package:flutter/material.dart';
import 'package:skripshot/category_detail_page.dart';
import 'package:skripshot/yolo_model.dart';
import 'camera_screen.dart';
//import 'detection_page.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await loadLabels();
  await YoloModel().loadModel(); // Load model when app starts
  runApp(MyApp());
}
Map<int, String> classLabels = {};

Future<void> loadLabels() async {
  final String jsonString = await rootBundle.loadString('assets/categories.json');
  final Map<String, dynamic> jsonData = json.decode(jsonString);
  classLabels = jsonData.map((key, value) => MapEntry(int.parse(key), value));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
class HomePage extends StatefulWidget{
  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PANDUAN MEMILAH SAMPAH', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          indicatorColor: Colors.green,
          tabs: [
            Tab(text: 'KATEGORI'),
            Tab(text: 'CARI BARANG'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          WasteCategoryGrid(),
          Center(child: Text('HALAMAN PENCARIAN OBJEK SAMPAH', style: TextStyle(fontSize: 18))),// HALAMAN PENCARIAN BARANG
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Camera Screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

class WasteCategoryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> categories = [
    {'icon': Icons.bolt, 'label': 'E-WASTE'},
    {'icon': Icons.wine_bar, 'label': 'KACA'},
    {'icon': Icons.menu_book, 'label': 'KERTAS'},
    {'icon': Icons.build, 'label': 'LOGAM'},
    {'icon': Icons.eco, 'label': 'ORGANIK'},
    {'icon': Icons.local_drink, 'label': 'PLASTIK'},
    {'icon': Icons.delete, 'label': 'RESIDU'},
    {'icon': Icons.category, 'label': 'STYROFOAM'},
    {'icon': Icons.checkroom, 'label': 'TEKSTIL'},
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

