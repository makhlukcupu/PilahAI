import 'dart:async';

import 'package:flutter/material.dart';
import 'package:skripshot/models.dart';
import 'package:skripshot/data_loader.dart';
import 'package:skripshot/waste_detail_page.dart';

class AllObjectsPage extends StatefulWidget {
  const AllObjectsPage({Key? key}) : super(key: key);

  @override
  State<AllObjectsPage> createState() => _AllObjectsPageState();
}

class _AllObjectsPageState extends State<AllObjectsPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<WasteObject> _allObjects = [];
  List<WasteObject> _filteredObjects = [];


  @override
  void initState() {
    super.initState();
    _allObjects = WasteRepository.objects;
    _filteredObjects = _allObjects;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.toLowerCase();
      List<WasteObject> matchNama = [];
      List<WasteObject> matchAlias = [];

      for (var objek in _allObjects) {
        final namaLower = objek.name.toLowerCase();
        final aliasMatch = objek.alias.any((alias) => alias.toLowerCase().contains(query));

        if (namaLower.contains(query)) {
          matchNama.add(objek);
        } else if (aliasMatch) {
          matchAlias.add(objek);
        }
      }
      setState(() {
        _filteredObjects = [...matchNama, ...matchAlias];
      });
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cari Sampah'),
        backgroundColor: Colors.green[100],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau kategori...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredObjects.isEmpty
                ? const Center(child: Text('Tidak ada hasil.'))
                : ListView.builder(
              itemCount: _filteredObjects.length,
              itemBuilder: (context, index) {
                final obj = _filteredObjects[index];
                return ListTile(
                  leading: (() {
                    final cat = WasteRepository.categories
                        .where((c) => c.id == obj.categoryId)
                        .cast<Category?>()
                        .firstOrNull;

                    if (cat?.icon != null && cat!.icon.isNotEmpty) {
                      return Image.asset(cat.icon);
                    } else {
                      return const Icon(Icons.image_not_supported);
                    }
                  })(),
                  title: Text(obj.name),
                  subtitle: Text(
                    obj.categoryId == 'organic'
                        ? 'Organik'
                        : obj.recyclable
                        ? "Daur Ulang"
                        : obj.hazardous
                        ? "B3"
                        : "Residu",
                    style: TextStyle(
                      color: obj.recyclable
                          ? Colors.blue
                          : obj.hazardous
                          ? Colors.red
                          : Colors.orange,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    final cat = WasteRepository.categories
                        .where((c) => c.id == obj.categoryId)
                        .cast<Category?>()
                        .firstOrNull;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ObjectDetailPage(
                          object: obj,
                          icon: cat!.icon, // kirim null kalau tidak punya icon
                        ),
                      ),
                    );
                  },
                );

              },
            ),
          ),
        ],
      ),
    );
  }
}
