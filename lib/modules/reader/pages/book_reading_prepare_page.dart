import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/book_model.dart';
import '../services/book_offline_cache.dart';
import '../services/book_offline_session.dart';
import '../utils/book_pages_loader.dart';
import '../widgets/book_reading_loading_view.dart';
import 'animated_book_reader_page.dart';
import 'digital_book_reader_page.dart';
import 'interactive_book_reader_page.dart';
import 'reader_page.dart';
import 'reader_webview_page.dart';

/// Carrega o livro, baixa todas as imagens e só depois abre o leitor.
class BookReadingPreparePage extends StatefulWidget {
  const BookReadingPreparePage({
    super.key,
    required this.book,
    required this.savedPage,
    required this.savedStep,
  });

  final BookModel book;
  final int savedPage;
  final int savedStep;

  @override
  State<BookReadingPreparePage> createState() => _BookReadingPreparePageState();
}

class _BookReadingPreparePageState extends State<BookReadingPreparePage> {
  String _phase = 'A preparar o livro…';
  double _progress = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  Future<void> _prepare() async {
    setState(() {
      _error = null;
      _phase = 'A carregar páginas…';
      _progress = 0.05;
    });

    try {
      final result = await BookOfflineCache.instance.prepare(
        book: widget.book,
        fetchFromNetwork: () => loadBookForReading(widget.book),
        onProgress: (phase, progress) {
          if (!mounted) return;
          setState(() {
            _phase = phase;
            _progress = progress;
          });
        },
      );

      if (!mounted) return;

      BookOfflineSession.activate(
        result.book.id,
        result.urlToLocalPath,
      );

      await _openReader(result.book);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao preparar: $e';
        _progress = 0;
      });
    }
  }

  Future<void> _openReader(BookModel loaded) async {
    final page = loaded.kind == BookKind.digital
        ? DigitalBookReaderPage(
            book: loaded,
            initialPdfPage: widget.savedPage > 0 ? widget.savedPage : 1,
          )
        : _readerForKind(loaded);

    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _readerForKind(BookModel loaded) {
    switch (loaded.kind) {
      case BookKind.animated:
        return AnimatedBookReaderPage(
          book: loaded,
          initialSlotIndex: widget.savedPage,
          skipInitialLoad: true,
        );
      case BookKind.interactive:
        return InteractiveBookReaderPage(
          book: loaded,
          initialSceneIndex: widget.savedPage,
          skipInitialLoad: true,
        );
      case BookKind.digital:
        return DigitalBookReaderPage(
          book: loaded,
          initialPdfPage: widget.savedPage > 0 ? widget.savedPage : 1,
        );
      case BookKind.legacy:
        final slidebook = loaded.slidebookLink;
        if (slidebook != null &&
            slidebook.isNotEmpty &&
            !loaded.hasNativePages) {
          return ReaderWebViewPage(slidebookUrl: slidebook);
        }
        return ReaderPage(
          bookId: loaded.id.toString(),
          initialPage: widget.savedPage,
          initialStep: widget.savedStep,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E0E1E),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.amberAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    setState(() => _error = null);
                    _prepare();
                  },
                  child: const Text('Tentar novamente'),
                ),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: BookReadingLoadingView(
        title: widget.book.title,
        phaseLabel: _phase,
        progress: _progress,
        coverUrl: widget.book.coverImage,
      ),
    );
  }
}
