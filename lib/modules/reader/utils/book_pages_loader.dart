import '../../../core/models/book_model.dart';
import '../../../core/services/luditeca_api_service.dart';

/// Carrega o livro completo para leitura.
/// A listagem `GET /books` não inclui `pages`, `pdf_url` nem `epub_url`.
Future<BookModel?> loadBookForReading(BookModel book) async {
  final needsPages = book.pages.isEmpty;
  final needsDigital = !book.hasDigitalAsset &&
      (book.kind == BookKind.digital || book.isPdf);

  if (!needsPages && !needsDigital) return book;

  final api = LuditecaApiService();
  final raw = await api.getBookById(book.id.toString());
  if (raw == null) return null;

  final full = BookModel.fromJson(raw);
  return book.copyWith(
    pages: full.pages.isNotEmpty ? full.pages : book.pages,
    quiz: full.quiz.isNotEmpty ? full.quiz : book.quiz,
    soundtrackUrl: full.soundtrackUrl ?? book.soundtrackUrl,
    pdfUrl: full.pdfUrl ?? book.pdfUrl,
    epubUrl: full.epubUrl ?? book.epubUrl,
    isPdf: full.isPdf || book.isPdf,
  );
}
