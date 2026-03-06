class CategoryModel {
  final int id;
  final String name;
  final String? imageUrl;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name)';
  }
}
