class RecyclingIdea {
  final String title;
  final String youtubeId;

  RecyclingIdea({required this.title, required this.youtubeId});

  factory RecyclingIdea.fromJson(Map<String, dynamic> json) {
    return RecyclingIdea(
      title: json['title'],
      youtubeId: json['youtubeId'],
    );
  }
}

class RecyclableObject {
  final String id;
  final String name;
  final String icon;
  final bool recyclable;
  final String description;
  final List<RecyclingIdea> ideas;

  RecyclableObject({
    required this.id,
    required this.name,
    required this.icon,
    required this.recyclable,
    required this.description,
    required this.ideas,
  });

  factory RecyclableObject.fromJson(Map<String, dynamic> json) {
    var ideasJson = json['ideas'] ?? [];
    return RecyclableObject(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      recyclable: json['recyclable'],
      description: json['description'],
      ideas: List<RecyclingIdea>.from(
        ideasJson.map((idea) => RecyclingIdea.fromJson(idea)),
      ),
    );
  }
}

class Category {
  final String id;
  final String name;
  final String icon;
  final bool recyclable;
  final String description;
  final String recyclingInstructions;
  final List<RecyclableObject> objects;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.recyclable,
    required this.description,
    required this.recyclingInstructions,
    required this.objects,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      recyclable: json['recyclable'],
      description: json['description'],
      recyclingInstructions: json['recyclingInstructions'],
      objects: List<RecyclableObject>.from(
        (json['objects'] as List).map((obj) => RecyclableObject.fromJson(obj)),
      ),
    );
  }
}
