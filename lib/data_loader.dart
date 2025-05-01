import 'dart:convert';
import 'package:flutter/services.dart';
import 'models.dart';
import 'package:collection/collection.dart';

// Keep track of loaded categories
List<Category> _loadedCategories = [];

Future<List<Category>> loadCategoriesFromJson() async {
  if (_loadedCategories.isNotEmpty) return _loadedCategories;

  final jsonString = await rootBundle.loadString('assets/data/data.json');
  final Map<String, dynamic> jsonData = json.decode(jsonString);

  _loadedCategories = List<Category>.from(
    jsonData['categories'].map((cat) => Category.fromJson(cat)),
  );

  return _loadedCategories;
}

// 🔍 Find category by ID
Future<Category?> findCategoryById(String id) async {
  final categories = await loadCategoriesFromJson();
  return categories.firstWhereOrNull((cat) => cat.id == id);
}

// 🔍 Find object by ID (and return both the object and its parent category)
Future<Map<String, dynamic>?> findObjectById(String objectId) async {
  final categories = await loadCategoriesFromJson();
  for (final category in categories) {
    for (final obj in category.objects) {
      if (obj.name == objectId) {
        return {
          'object': obj,
          'category': category,
        };
      }
    }
  }
  return null;
}
