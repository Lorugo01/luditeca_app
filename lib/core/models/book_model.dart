import 'dart:convert';

class BookModel {
  final int id;
  final String title;
  final String? author;
  final String? description;
  final String? coverImage;
  final Map<String, dynamic>? pages;
  final String? slidebookLink;
  final DateTime createdAt;
  final int? authorId;
  final int categoryId;
  bool isFavorite;

  BookModel({
    required this.id,
    required this.title,
    this.author,
    this.description,
    this.coverImage,
    this.pages,
    this.slidebookLink,
    required this.createdAt,
    this.authorId,
    required this.categoryId,
    this.isFavorite = false,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    try {
      final pagesData = json['pages'];
      Map<String, dynamic>? parsedPages;

      if (pagesData != null) {
        if (pagesData is String) {
          // Se pages vier como string JSON, vamos tentar fazer o parse
          try {
            parsedPages = Map<String, dynamic>.from(jsonDecode(pagesData));
          } catch (_) {}
        } else if (pagesData is Map) {
          parsedPages = Map<String, dynamic>.from(pagesData);
        }
      }

      return BookModel(
        id: json['id'] as int,
        title: json['title'] as String,
        author: json['author'] as String?,
        description: json['description'] as String?,
        coverImage: json['cover_image'] as String?,
        pages: parsedPages,
        slidebookLink: json['link_slidebook'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        authorId: json['author_id'] as int?,
        categoryId: json['category_id'] as int,
        isFavorite: false,
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'cover_image': coverImage,
      'pages': pages,
      'created_at': createdAt.toIso8601String(),
      'author_id': authorId,
      'category_id': categoryId,
      'is_favorite': isFavorite,
    };
  }

  @override
  String toString() {
    return 'BookModel(id: $id, title: $title, categoryId: $categoryId, author: $author)';
  }
}
