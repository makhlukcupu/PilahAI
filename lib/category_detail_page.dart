import 'package:flutter/material.dart';
import 'models.dart';
import 'waste_detail_page.dart'; // For when user taps an object
import 'package:skripshot/models.dart';
import 'package:skripshot/data_loader.dart';

class CategoryDetailPage extends StatelessWidget {
  final Category category;

  CategoryDetailPage({super.key, required this.category});
  final objects = WasteRepository.objects;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              left: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 56, left: 16, right: 16, bottom: 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Image.asset(category.icon, width: 48, height: 48)),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        category.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Center(
                    //   child: Text(
                    //     isRecyclable ? "Dapat Didaur Ulang" : "Residu",
                    //     style: TextStyle(
                    //       color: isRecyclable ? Colors.green : Colors.red,
                    //       fontSize: 14,
                    //       fontWeight: FontWeight.w500,
                    //     ),
                    //   ),
                    // ),
                    const SizedBox(height: 16),
                    Text(
                      category.description,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                    const Divider(height: 32),
                    const Text(
                      "Cara Daur Ulang",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.handling,
                      style: const TextStyle(fontSize: 15, height: 1.4),
                    ),
                    const Divider(height: 32),
                    ExpansionTile(
                      title: const Text(
                        "Contoh Objek",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      children: category.objects.map((obj) {
                        return ListTile(
                          title: Text(objects.firstWhere((o) => o.id == obj).name),
                          //leading: Text(obj.icon, style: const TextStyle(fontSize: 24)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ObjectDetailPage(object: WasteRepository.objects.firstWhere((o) => o.id == obj), icon: category.icon),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
