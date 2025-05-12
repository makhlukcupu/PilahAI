class Category {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String handling;
  final List<int> objects;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.handling,
    required this.objects,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    icon: json['icon'] as String,
    description: json['description'] as String,
    handling: json['handling'] as String,
    objects: List<int>.from(json['objects'] as List), // Explicit cast to List<String>
  );
}

// class RecyclingIdea {
//   final String title;
//   final String url;
//
//   RecyclingIdea({required this.title, required this.url});
//
//   factory RecyclingIdea.fromJson(Map<String, dynamic> json) => RecyclingIdea(
//     title: json['title'],
//     url: json['youtube_url'],
//   );
// }

class WasteObject {
  final int id;
  final String name;
  final String categoryId;
  //final String icon;
  final String description;
  final bool recyclable;
  final bool hazardous;
  final List<dynamic> alias;//harusnya string, tapi ada typo atau error di database, ada yang kebaca bukan string
  final List<Map<String, dynamic>> recyclingIdeas;

  WasteObject({
    required this.id,
    required this.name,
    required this.categoryId,
    //required this.icon,
    required this.description,
    required this.recyclable,
    required this.hazardous,
    required this.alias,
    required this.recyclingIdeas,
  });

  factory WasteObject.fromJson(Map<String, dynamic> json) => WasteObject(
    id: json["id"],
    name: json['name'],
    categoryId: json['category'],
    //icon: json['icon'],
    description: json['desc'],
    recyclable: json['recyclable'],
    hazardous: json['hazardous'],
    alias: json['alias']??[],
    recyclingIdeas: (json['reuse_ideas'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .toList());
}
