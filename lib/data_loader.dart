import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:skripshot/models.dart';

class WasteRepository {
  static List<Category> categories = [];
  static List<WasteObject> objects = [];

  static Future<void> loadFromJson() async {
    final jsonData = await rootBundle.loadString('assets/waste_database.json');
    final parsed = jsonDecode(jsonData);

    categories = (parsed['categories'] as List)
        .map((e) => Category.fromJson(e))
        .toList();

    objects = (parsed['waste_items'] as List)
        .map((e) => WasteObject.fromJson(e))
        .toList();
    print("data_loaded");
  }
}
