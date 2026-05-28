class BookQuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  const BookQuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  bool get isValid =>
      question.trim().isNotEmpty &&
      options.length >= 2 &&
      correctIndex >= 0 &&
      correctIndex < options.length;

  factory BookQuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    final options = <String>[];
    if (rawOptions is List) {
      for (final opt in rawOptions) {
        if (opt != null) options.add(opt.toString());
      }
    }
    final correct = json['correct'];
    final correctIndex = correct is int
        ? correct
        : int.tryParse('${correct ?? ''}') ?? 0;
    return BookQuizQuestion(
      question: (json['question'] ?? '').toString(),
      options: options,
      correctIndex: correctIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'question': question,
        'options': options,
        'correct': correctIndex,
      };
}

List<BookQuizQuestion> parseBookQuizList(List<Map<String, dynamic>> raw) {
  return raw
      .map(BookQuizQuestion.fromJson)
      .where((q) => q.isValid)
      .toList(growable: false);
}
