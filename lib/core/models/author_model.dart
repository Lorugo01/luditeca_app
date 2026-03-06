class AuthorModel {
  final int id;
  final String name;
  final String? biography;
  final DateTime createdAt;

  AuthorModel({
    required this.id,
    required this.name,
    this.biography,
    required this.createdAt,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      id: json['id'] as int,
      name: json['name'] as String,
      biography: json['biography'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'biography': biography,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
