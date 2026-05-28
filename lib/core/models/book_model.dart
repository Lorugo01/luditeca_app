import 'dart:convert';

enum BookKind {
  animated,
  interactive,
  digital,
  legacy,
}

BookKind _parseBookKind(dynamic value) {
  if (value is String) {
    switch (value.toLowerCase().trim()) {
      case 'animated':
        return BookKind.animated;
      case 'interactive':
        return BookKind.interactive;
      case 'digital':
        return BookKind.digital;
    }
  }
  return BookKind.legacy;
}

List<Map<String, dynamic>> _parseQuiz(dynamic raw) {
  if (raw == null) return const [];
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {}
  }
  return const [];
}

class BookModel {
  final int id;
  final String title;
  final String? author;
  final String? description;
  final String? ageRange;
  final String? coverImage;
  final List<Map<String, dynamic>> pages;
  final String? slidebookLink;
  final DateTime createdAt;
  final int? authorId;
  final int categoryId;
  final BookKind kind;
  final String? pdfUrl;
  final String? epubUrl;
  final String? soundtrackUrl;
  final List<Map<String, dynamic>> quiz;
  final bool isPdf;
  bool isFavorite;

  BookModel({
    required this.id,
    required this.title,
    this.author,
    this.description,
    this.ageRange,
    this.coverImage,
    required this.pages,
    this.slidebookLink,
    required this.createdAt,
    this.authorId,
    required this.categoryId,
    this.kind = BookKind.legacy,
    this.pdfUrl,
    this.epubUrl,
    this.soundtrackUrl,
    this.quiz = const [],
    this.isPdf = false,
    this.isFavorite = false,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    final pagesData = json['pages'];
    final parsedPages = <Map<String, dynamic>>[];

    if (pagesData != null) {
      if (pagesData is String) {
        try {
          final decoded = jsonDecode(pagesData);
          if (decoded is List) {
            parsedPages.addAll(
              decoded
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item)),
            );
          } else if (decoded is Map<String, dynamic>) {
            if (decoded['pages'] is List) {
              parsedPages.addAll(
                (decoded['pages'] as List)
                    .whereType<Map>()
                    .map((item) => Map<String, dynamic>.from(item)),
              );
            }
          }
        } catch (_) {}
      } else if (pagesData is List) {
        parsedPages.addAll(
          pagesData
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item)),
        );
      } else if (pagesData is Map<String, dynamic> &&
          pagesData['pages'] is List) {
        parsedPages.addAll(
          (pagesData['pages'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item)),
        );
      }
    }

    final quiz = _parseQuiz(json['book_quiz'] ?? json['quiz']);

    String? asNonEmptyString(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return BookModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      title: (json['title'] ?? '').toString(),
      author: asNonEmptyString(json['author']),
      description: asNonEmptyString(json['description']),
      ageRange: asNonEmptyString(json['age_range'] ?? json['ageRange']),
      coverImage: asNonEmptyString(json['cover_image'] ?? json['coverImage']),
      pages: parsedPages,
      slidebookLink: asNonEmptyString(json['link_slidebook']),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ??
          DateTime.now(),
      authorId: json['author_id'] is int
          ? json['author_id'] as int
          : int.tryParse('${json['author_id']}'),
      categoryId: json['category_id'] is int
          ? json['category_id'] as int
          : int.tryParse('${json['category_id']}') ?? 0,
      kind: _parseBookKind(json['book_type'] ?? json['bookType']),
      pdfUrl: asNonEmptyString(json['pdf_url']),
      epubUrl: asNonEmptyString(json['epub_url']),
      soundtrackUrl: asNonEmptyString(json['soundtrack_url']),
      quiz: quiz,
      isPdf: json['is_pdf'] == true,
      isFavorite: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'age_range': ageRange,
      'cover_image': coverImage,
      'pages': pages,
      'link_slidebook': slidebookLink,
      'created_at': createdAt.toIso8601String(),
      'author_id': authorId,
      'category_id': categoryId,
      'book_type': kind.name,
      'pdf_url': pdfUrl,
      'epub_url': epubUrl,
      'soundtrack_url': soundtrackUrl,
      'book_quiz': quiz,
      'is_pdf': isPdf,
      'is_favorite': isFavorite,
    };
  }

  @override
  String toString() {
    return 'BookModel(id: $id, title: $title, kind: ${kind.name}, categoryId: $categoryId, author: $author)';
  }

  bool get hasNativePages => pages.isNotEmpty;
  bool get hasDigitalAsset =>
      (pdfUrl != null && pdfUrl!.isNotEmpty) ||
      (epubUrl != null && epubUrl!.isNotEmpty);

  BookModel copyWith({
    List<Map<String, dynamic>>? pages,
    List<Map<String, dynamic>>? quiz,
    String? soundtrackUrl,
    String? pdfUrl,
    String? epubUrl,
    bool? isPdf,
  }) {
    return BookModel(
      id: id,
      title: title,
      author: author,
      description: description,
      ageRange: ageRange,
      coverImage: coverImage,
      pages: pages ?? this.pages,
      slidebookLink: slidebookLink,
      createdAt: createdAt,
      authorId: authorId,
      categoryId: categoryId,
      kind: kind,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      epubUrl: epubUrl ?? this.epubUrl,
      soundtrackUrl: soundtrackUrl ?? this.soundtrackUrl,
      quiz: quiz ?? this.quiz,
      isPdf: isPdf ?? this.isPdf,
      isFavorite: isFavorite,
    );
  }
}
