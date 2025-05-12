import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'data_loader.dart'; // For WasteRepository or static object list
import 'package:collection/collection.dart';

class LastOpenedObjectManager {
  static const _key = 'recent_objects';
  static const _maxItems = 5;

  /// Save object by its ID to SharedPreferences after viewing
  Future<void> saveLastOpenedObject(WasteObject object) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> ids = prefs.getStringList(_key) ?? [];

    // Remove if already exists
    ids.remove(object.id.toString());
    // Add to the front
    ids.insert(0, object.id.toString());

    // Keep max 5 items
    if (ids.length > _maxItems) {
      ids = ids.sublist(0, _maxItems);
    }

    await prefs.setStringList(_key, ids);
  }

  /// Load recently opened object IDs and return actual object data
  Future<List<WasteObject>> loadLastOpenedObjects() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];

    // Match with global static object list
    final allObjects = WasteRepository.objects;

    // Allow null to be returned if no match is found
    return ids
        .map((id) => allObjects.firstWhere(
          (o) => o.id.toString() == id,
    ))
        .whereType<WasteObject>() // Allow null in the list
        .toList();
  }

  /// Optional: clear history
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
