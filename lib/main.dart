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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skripshot/last_opened_object_manager.dart';
import 'package:skripshot/waste_detail_page.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart'; // For rootBundle

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start all initialization tasks in the background
  final initialization = _initializeApp();

  runApp(
    MaterialApp(
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: initialization,
        builder: (context, snapshot) {
          // Show splash screen while initializing
          if (snapshot.connectionState != ConnectionState.done) {
            return SplashScreen(
              progress: _calculateProgress(snapshot), // Optional progress
            );
          }

          // Show error screen if initialization failed
          if (snapshot.hasError) {
            return ErrorScreen(error: snapshot.error);
          }

          // Return main app when everything is ready
          return HomePage();
        },
      ),
    ),
  );
}

// Combined initialization function
Future<void> _initializeApp() async {
  try {
    await loadLabels();
    await YoloModel().loadModel();
    await WasteRepository.loadFromJson();
    await loadObjectMapping();
    // await clearOldData(); // Uncomment if needed
  } catch (e) {
    debugPrint("Initialization failed: $e");
    rethrow;
  }
}

// Your existing functions (unchanged)
Map<int, String> classLabels = {};
Map<int, WasteObject> objectMap = {};

Future<void> loadLabels() async {
  final String jsonString = await rootBundle.loadString('assets/categories.json');
  final Map<String, dynamic> jsonData = json.decode(jsonString);
  classLabels = jsonData.map((key, value) => MapEntry(int.parse(key), value));
}

Future<void> loadObjectMapping() async {
  final String jsonString = await rootBundle.loadString('assets/object_mapping.json');
  final Map<String, dynamic> jsonData = json.decode(jsonString);
  objectMap = jsonData.map((key, value) => MapEntry(int.parse(key), WasteRepository.objects.firstWhere((o) => o.id == value)));
}

Future<List<WasteObject>> loadRecentObjects() async {
  final prefs = await SharedPreferences.getInstance();
  final ids = prefs.getStringList('recent_objects') ?? [];
  return ids
      .map((name) => WasteRepository.objects.firstWhere((o) => o.name == name))
      .whereType<WasteObject>()
      .toList();
}

// New splash screen widget
class SplashScreen extends StatelessWidget {
  final double? progress;

  const SplashScreen({this.progress, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/splash.png'),
            if (progress != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Optional error screen
class ErrorScreen extends StatelessWidget {
  final dynamic error;

  const ErrorScreen({required this.error, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const Text("Initialization Error"),
            Text(error.toString()),
            ElevatedButton(
              onPressed: () => main(), // Retry
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function for progress calculation
double? _calculateProgress(AsyncSnapshot snapshot) {
  // Implement your progress logic here if needed
  // Example: return 0.5 when halfway through initialization
  return null; // Return null to hide progress indicator
}


class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware{
  final categories = WasteRepository.categories;
  List<WasteObject> recentObjects = [];


  @override
  void initState() {
    super.initState();
    _loadRecentObjects();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    _loadRecentObjects(); // load initially
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when user returns from another page
    _loadRecentObjects();
  }

  Future<void> _loadRecentObjects() async {
    final recent = await LastOpenedObjectManager().loadLastOpenedObjects();
    setState(() {
      recentObjects = recent;
    });
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
            if (recentObjects.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text("Baru Dilihat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentObjects.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, index) {
                    final obj = recentObjects[index];
                    return ObjectCard(
                      object: obj,
                      icon: WasteRepository.categories.firstWhere((o) => o.id == obj.categoryId).icon,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ObjectDetailPage(object: obj, icon: WasteRepository.categories.firstWhere((o) => o.id == obj.categoryId).icon ,)),
                        );
                      },
                    );
                  },
                ),
              ),
            ],

            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16),
            //   child: Text("Terakhir dilihat", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            // ),
            // SizedBox(height: 12),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16),
            //   child: SuggestionCard(name: "Botol Plastik", recyclable: true),
            // ),
            //
            // SizedBox(height: 24),

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


class ObjectCard extends StatelessWidget {
  final WasteObject object;
  final String icon;
  final VoidCallback onTap;

  const ObjectCard({Key? key, required this.object, required this.onTap, required this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(icon, width: 40, height: 40,),//icon ganti nanti yang sesuai data
            const SizedBox(height: 8),
            Text(object.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              object.recyclable ? 'Daur Ulang' : object.hazardous? 'Beracun atau Berbahaya (B3)' : 'Tidak Daur Ulang',
              style: TextStyle(
                color: object.recyclable ? Colors.green : object.hazardous? Colors.brown : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// class SuggestionCard extends StatelessWidget {
//   final String name;
//   final bool recyclable;
//
//   const SuggestionCard({required this.name, required this.recyclable});
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: ListTile(
//         leading: Icon(LucideIcons.box, color: Colors.green[700]),
//         title: Text(name),
//         subtitle: Text(
//           recyclable ? "Dapat didaur ulang" : "Tidak dapat didaur ulang",
//           style: TextStyle(color: recyclable ? Colors.green : Colors.red),
//         ),
//         trailing: Icon(Icons.arrow_forward_ios, size: 16),
//         onTap: () {
//           // navigate to object detail
//         },
//       ),
//     );
//   }
// }