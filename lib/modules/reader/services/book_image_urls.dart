import '../../../core/models/book_model.dart';
import '../models/animated_slot.dart';
import '../models/book_quiz.dart';
import '../models/story_page.dart';

/// Recolhe URLs de imagens do livro para pré-download antes da leitura.
class BookImageUrls {
  BookImageUrls._();

  static List<String> fromBook(BookModel book) {
    final urls = <String>{};
    void add(String? raw) {
      if (raw == null) return;
      final u = raw.trim();
      if (u.isEmpty) return;
      if (u.startsWith('http://') || u.startsWith('https://')) {
        urls.add(u);
      }
    }

    add(book.coverImage);

    switch (book.kind) {
      case BookKind.animated:
        _collectAnimated(book, add);
        break;
      case BookKind.interactive:
        for (final scene in extractStoryPages(book.pages)) {
          add(scene.imageUrl);
        }
        break;
      case BookKind.legacy:
      case BookKind.digital:
        _collectLegacyPages(book.pages, add);
        break;
    }

    return urls.toList(growable: false);
  }

  static void _collectAnimated(
    BookModel book,
    void Function(String? url) add,
  ) {
    final quiz = parseBookQuizList(book.quiz);
    final slots = buildAnimatedSlots(book.pages, quiz);
    for (final slot in slots) {
      if (slot.kind == AnimatedSlotKind.page) {
        add(slot.page?.imageUrl);
        add(slot.page?.narrationUrl);
      }
    }
  }

  static void _collectLegacyPages(
    List<Map<String, dynamic>> pages,
    void Function(String? url) add,
  ) {
    for (final page in pages) {
      add(page['image_url']?.toString());
      add(page['background']?.toString());

      final bg = page['background'];
      if (bg is Map) {
        add(bg['url']?.toString());
      }

      final elements = page['elements'];
      if (elements is! List) continue;
      for (final raw in elements) {
        if (raw is! Map) continue;
        final type = '${raw['type'] ?? ''}'.toLowerCase();
        if (type == 'image' || type.contains('image')) {
          add(raw['content']?.toString());
          add(raw['src']?.toString());
          add(raw['url']?.toString());
        }
      }

      final nodes = page['nodes'];
      if (nodes is! List) continue;
      for (final raw in nodes) {
        if (raw is! Map) continue;
        final type = '${raw['type'] ?? ''}'.toLowerCase();
        if (type != 'image') continue;
        final props = raw['props'];
        if (props is Map) {
          add(props['content']?.toString());
          add(props['url']?.toString());
        }
      }
    }
  }
}
