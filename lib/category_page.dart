import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        onPressed: () {},
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(categories[index]['icon'], size: 50, color: Colors.grey[700]),
            SizedBox(height: 8),
            Text(categories[index]['label'],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        );
      },
    );
  }
}
