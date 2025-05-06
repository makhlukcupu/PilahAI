import 'package:flutter/material.dart';
import 'package:skripshot/category_detail_page.dart';
import 'package:skripshot/yolo_model.dart';
import 'camera_screen.dart';
//import 'detection_page.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lucide_icons/lucide_icons.dart';
import 'data_loader.dart';
import 'models.dart';
import 'package:skripshot/search_page.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await loadLabels();
  await YoloModel().loadModel(); // Load model when app starts
  await WasteRepository.loadFromJson();//load all waste data
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

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final categories = WasteRepository.categories;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Halo 👋", style: TextStyle(fontSize: 30, color: Colors.green[800])),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.green[800]),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AllObjectsPage()),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey[600]),
                      SizedBox(width: 10),
                      Text(
                        "Cari sampah...",
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),

            // 🧭 Category Carousel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("Kategori", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 120,
              child:
              //FutureBuilder<List<Category>>(
              //   future: futureCategories,
              //   builder: (context, snapshot) {
              //     if (snapshot.connectionState == ConnectionState.waiting) {
              //       return const Center(child: CircularProgressIndicator());
              //     } else if (snapshot.hasError) {
              //       return const Center(child: Text("Gagal memuat kategori"));
              //     }
              //
              //     final categories = snapshot.data!;
                ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryDetailPage(category: category),
                          ),
                        );
                      },
                      child: CategoryCard(name: category.name, iconEmojiOrPath: category.icon),
                    );
                  },
                ),
                //},
              ),
            //),

            SizedBox(height: 24),

            // 🧠 Smart Suggestions (static for now)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("Terakhir dilihat", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SuggestionCard(name: "Botol Plastik", recyclable: true),
            ),

            SizedBox(height: 24),

            // ♻️ Tip of the Day
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("♻️ Tips Hari Ini", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Gunakan kembali botol plastik sebagai pot tanaman atau tempat pensil!",
                    style: TextStyle(color: Colors.green[900]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // 📸 Floating Camera Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CameraScreen(),
            ),
          );
        },
        backgroundColor: Colors.green[700],
        child: Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }
}

// --- Reusable Widgets ---

class CategoryCard extends StatelessWidget {
  final String name;
  final String iconEmojiOrPath;

  const CategoryCard({required this.name, required this.iconEmojiOrPath});

  bool _isAssetPath(String input) {
    return input.endsWith('.png') || input.endsWith('.jpg') || input.contains('assets/');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _isAssetPath(iconEmojiOrPath)
              ? Image.asset(iconEmojiOrPath, width: 48, height: 48)
              : Text(iconEmojiOrPath, style: TextStyle(fontSize: 32)),
          SizedBox(height: 8),
          Text(name, style: TextStyle(color: Colors.green[900])),
        ],
      ),
    );
  }
}

class SuggestionCard extends StatelessWidget {
  final String name;
  final bool recyclable;

  const SuggestionCard({required this.name, required this.recyclable});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(LucideIcons.box, color: Colors.green[700]),
        title: Text(name),
        subtitle: Text(
          recyclable ? "Dapat didaur ulang" : "Tidak dapat didaur ulang",
          style: TextStyle(color: recyclable ? Colors.green : Colors.red),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // navigate to object detail
        },
      ),
    );
  }
}