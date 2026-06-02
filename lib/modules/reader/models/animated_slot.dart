import 'book_quiz.dart';

enum AnimatedSlotKind { page, quiz }

class AnimatedPage {
  final String? imageUrl;
  final String? text;
  final String? narrationUrl;
  final bool isGif;
  final int pageNumber;

  const AnimatedPage({
    required this.pageNumber,
    this.imageUrl,
    this.text,
    this.narrationUrl,
    this.isGif = false,
  });

  factory AnimatedPage.fromJson(Map<String, dynamic> json, int fallbackIndex) {
    final pageNumberRaw = json['page_number'];
    final pageNumber = pageNumberRaw is int
        ? pageNumberRaw
        : int.tryParse('${pageNumberRaw ?? ''}') ?? fallbackIndex;
    final narrationRaw = json['narration_url'] ?? json['narrationUrl'];
    return AnimatedPage(
      pageNumber: pageNumber,
      imageUrl: (json['image_url'] ?? '').toString().trim().isEmpty
          ? null
          : (json['image_url'] as Object).toString().trim(),
      text: (json['text'] ?? '').toString().trim().isEmpty
          ? null
          : (json['text'] as Object).toString(),
      narrationUrl: narrationRaw == null || '$narrationRaw'.trim().isEmpty
          ? null
          : '$narrationRaw'.trim(),
      isGif: json['is_gif'] == true || json['mediaKind'] == 'gif',
    );
  }
}

class AnimatedSlot {
  final AnimatedSlotKind kind;
  final AnimatedPage? page;
  final BookQuizQuestion? quiz;

  const AnimatedSlot._({
    required this.kind,
    this.page,
    this.quiz,
  });

  factory AnimatedSlot.page(AnimatedPage page) =>
      AnimatedSlot._(kind: AnimatedSlotKind.page, page: page);

  factory AnimatedSlot.quiz(BookQuizQuestion quiz) =>
      AnimatedSlot._(kind: AnimatedSlotKind.quiz, quiz: quiz);
}

bool _isQuizPage(Map<String, dynamic> page) {
  final type = (page['page_type'] ?? '').toString().toLowerCase();
  return type == 'quiz';
}

bool _isStoryOrReadingPage(Map<String, dynamic> page) {
  final type = (page['page_type'] ?? 'reading').toString().toLowerCase();
  return type == 'reading' || type.isEmpty || type == 'story';
}

bool _isMetaRow(Map<String, dynamic> page) {
  final type = (page['page_type'] ?? '').toString().toLowerCase();
  return type == 'interactive_meta';
}

/// Verifica se a lista de páginas tem quiz inline (estilo timeline animada).
bool animatedPagesHaveInlineQuiz(List<Map<String, dynamic>> pages) {
  return pages.any(_isQuizPage);
}

/// Constrói a sequência de slots para o leitor animado.
///
/// Comportamento espelha `buildAnimatedReaderSlots` em
/// `luditeca-vps/frontend/lib/bookContentTimeline.js`:
///
/// 1. Se houver quiz inline em `pages`, segue a ordem editorial (`page_number`).
/// 2. Caso contrário, todas as páginas válidas + quiz do livro no fim.
List<AnimatedSlot> buildAnimatedSlots(
  List<Map<String, dynamic>> pages,
  List<BookQuizQuestion> quizFallback,
) {
  final cleaned = pages.where((p) => !_isMetaRow(p)).toList();

  if (animatedPagesHaveInlineQuiz(cleaned)) {
    final ordered = [...cleaned]
      ..sort((a, b) {
        final aNum = (a['page_number'] is num)
            ? (a['page_number'] as num).toInt()
            : int.tryParse('${a['page_number'] ?? ''}') ?? 0;
        final bNum = (b['page_number'] is num)
            ? (b['page_number'] as num).toInt()
            : int.tryParse('${b['page_number'] ?? ''}') ?? 0;
        return aNum.compareTo(bNum);
      });
    final slots = <AnimatedSlot>[];
    for (var i = 0; i < ordered.length; i++) {
      final page = ordered[i];
      if (_isQuizPage(page)) {
        final q = BookQuizQuestion.fromJson(page);
        if (q.isValid) slots.add(AnimatedSlot.quiz(q));
      } else {
        slots.add(AnimatedSlot.page(AnimatedPage.fromJson(page, i + 1)));
      }
    }
    return slots;
  }

  final slots = <AnimatedSlot>[];
  final ordered = cleaned.where(_isStoryOrReadingPage).toList()
    ..sort((a, b) {
      final aNum = (a['page_number'] is num)
          ? (a['page_number'] as num).toInt()
          : int.tryParse('${a['page_number'] ?? ''}') ?? 0;
      final bNum = (b['page_number'] is num)
          ? (b['page_number'] as num).toInt()
          : int.tryParse('${b['page_number'] ?? ''}') ?? 0;
      return aNum.compareTo(bNum);
    });
  for (var i = 0; i < ordered.length; i++) {
    slots.add(AnimatedSlot.page(AnimatedPage.fromJson(ordered[i], i + 1)));
  }
  for (final quiz in quizFallback) {
    if (quiz.isValid) slots.add(AnimatedSlot.quiz(quiz));
  }
  return slots;
}
