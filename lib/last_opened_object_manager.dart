import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'data_loader.dart'; // for WasteRepository or static object list

class LastOpenedObjectManager {
  static const _key = 'recent_objects';
  static const _maxItems = 5;

  /// Save object by its ID to SharedPreferences after 10 sec view
  Future<void> saveLastOpenedObject(WasteObject object) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> ids = prefs.getStringList(_key) ?? [];

    // Remove if already exists
    ids.remove(object.name);
    // Add to the front
    ids.insert(0, object.name);

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

    return ids
        .map((id) => allObjects.firstWhere(
          (o) => o.name == id
    ))
        .whereType<WasteObject>() // remove any nulls
        .toList();
  }

  /// Optional: clear history
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
