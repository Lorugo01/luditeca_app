import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:epub_view/epub_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../../core/models/book_model.dart';
import '../../../core/services/luditeca_api_service.dart';
import '../utils/book_pages_loader.dart';
import '../utils/reading_progress_helper.dart';
import '../services/book_offline_cache.dart';
import '../services/reading_xp_service.dart';

enum _DigitalView { pdf, epub, empty, loading }

class DigitalBookReaderPage extends StatefulWidget {
  final BookModel book;
  final int initialPdfPage;

  const DigitalBookReaderPage({
    super.key,
    required this.book,
    this.initialPdfPage = 1,
  });

  @override
  State<DigitalBookReaderPage> createState() => _DigitalBookReaderPageState();
}

class _DigitalBookReaderPageState extends State<DigitalBookReaderPage> {
  late final AuthController _authController;
  late final LuditecaApiService _apiService;

  /// Download de PDF/EPUB (ficheiros públicos, sem token).
  final Dio _mediaDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      responseType: ResponseType.bytes,
    ),
  );

  BookModel? _book;
  _DigitalView _view = _DigitalView.loading;
  String? _loadError;

  bool _pdfFallbackToWebView = false;
  bool _pdfUseMemory = false;
  Uint8List? _pdfBytes;
  String? _pdfError;
  final PdfViewerController _pdfController = PdfViewerController();
  double _pdfZoom = 1.0;
  bool _pdfDefaultZoomApplied = false;
  bool _pdfPageRestored = false;
  int _lastSavedPdfPage = 0;

  static const double _pdfZoomStep = 0.15;
  static const double _pdfMinZoom = 0.45;
  static const double _pdfMaxZoom = 4.0;

  WebViewController? _webViewController;
  EpubController? _epubController;
  String? _epubError;
  bool _completionRegistered = false;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _apiService = LuditecaApiService();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _bootstrap();
  }

  BookModel get _activeBook => _book ?? widget.book;

  bool get _isDesktopReader =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// No desktop o Syncfusion estica a pagina a largura total; single + zoom 1.0
  /// encaixa pela altura. No telemovel mantemos continuo a 100%.
  double get _defaultPdfZoom => 1.0;

  PdfPageLayoutMode get _pdfLayoutMode => _isDesktopReader
      ? PdfPageLayoutMode.single
      : PdfPageLayoutMode.continuous;

  /// Modo single usa scroll horizontal por defeito no Syncfusion.
  static const _pdfScrollDirection = PdfScrollDirection.vertical;

  void _applyDefaultPdfZoom() {
    if (_pdfDefaultZoomApplied) return;
    _pdfDefaultZoomApplied = true;
    final zoom = _defaultPdfZoom;
    _pdfController.zoomLevel = zoom;
    if (mounted) setState(() => _pdfZoom = zoom);
  }

  void _changePdfZoom(double delta) {
    final next =
        (_pdfController.zoomLevel + delta).clamp(_pdfMinZoom, _pdfMaxZoom);
    _pdfController.zoomLevel = next;
    if (mounted) setState(() => _pdfZoom = next);
  }

  void _resetPdfZoom() {
    _pdfController.zoomLevel = _defaultPdfZoom;
    if (mounted) setState(() => _pdfZoom = _defaultPdfZoom);
  }

  Widget _buildPdfZoomControls() {
    final percent = (_pdfZoom * 100).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Diminuir zoom',
          icon: const Icon(Icons.remove, size: 20),
          onPressed: _pdfZoom <= _pdfMinZoom
              ? null
              : () => _changePdfZoom(-_pdfZoomStep),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _resetPdfZoom,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              '$percent%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Aumentar zoom',
          icon: const Icon(Icons.add, size: 20),
          onPressed: _pdfZoom >= _pdfMaxZoom
              ? null
              : () => _changePdfZoom(_pdfZoomStep),
        ),
        IconButton(
          tooltip: 'Zoom padrao',
          icon: const Icon(Icons.fit_screen_outlined, size: 20),
          onPressed: _resetPdfZoom,
        ),
      ],
    );
  }

  Widget _pdfViewer({required Widget child}) {
    return Stack(
      children: [
        child,
        if (!_pdfFallbackToWebView)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Center(
              child: Material(
                color: const Color(0xFF16213E).withAlpha(230),
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildPdfZoomControls(),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _bootstrap() async {
    setState(() {
      _view = _DigitalView.loading;
      _loadError = null;
    });

    try {
      final loaded = await loadBookForReading(widget.book);
      if (!mounted) return;

      if (loaded == null) {
        setState(() {
          _view = _DigitalView.empty;
          _loadError = 'Não foi possível carregar o livro.';
        });
        return;
      }

      _book = loaded;
      if (_authController.isAuthenticated) {
        ReadingXpService.instance.beginSession(loaded.id);
      }
      _pickInitialView(loaded);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _view = _DigitalView.empty;
        _loadError = 'Erro ao carregar: $e';
      });
    }
  }

  void _pickInitialView(BookModel book) {
    final hasPdf = book.pdfUrl != null && book.pdfUrl!.isNotEmpty;
    final hasEpub = book.epubUrl != null && book.epubUrl!.isNotEmpty;

    if (hasPdf) {
      setState(() => _view = _DigitalView.pdf);
      _preparePdf(book.pdfUrl!);
    } else if (hasEpub) {
      setState(() => _view = _DigitalView.epub);
      _initEpub();
    } else {
      setState(() => _view = _DigitalView.empty);
    }
  }

  Future<void> _preparePdf(String url) async {
    setState(() {
      _pdfError = null;
      _pdfBytes = null;
      _pdfUseMemory = false;
      _pdfFallbackToWebView = false;
      _pdfDefaultZoomApplied = false;
      _pdfZoom = _defaultPdfZoom;
    });

    final cachedPath =
        await BookOfflineCache.instance.cachedPdfPath(_activeBook.id);
    if (cachedPath != null) {
      await _loadPdfFromFile(cachedPath);
      return;
    }

    // Em Windows/Web o viewer nativo por URL falha com frequência; bytes via HTTP é mais fiável.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      await _loadPdfBytes(url);
    }
  }

  Future<void> _loadPdfFromFile(String path) async {
    try {
      final bytes = await File(path).readAsBytes();
      if (!mounted) return;
      setState(() {
        _pdfBytes = Uint8List.fromList(bytes);
        _pdfUseMemory = true;
        _pdfError = null;
      });
    } catch (e) {
      debugPrint('PDF local falhou: $e');
      if (!mounted) return;
      setState(() => _pdfError = 'Não foi possível abrir o PDF guardado.');
    }
  }

  Future<void> _loadPdfBytes(String url) async {
    try {
      final response = await _mediaDio.get<List<int>>(url);
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw Exception('HTTP $status');
      }
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('PDF vazio.');
      }
      if (!mounted) return;
      setState(() {
        _pdfBytes = Uint8List.fromList(bytes);
        _pdfUseMemory = true;
        _pdfError = null;
      });
    } catch (e) {
      debugPrint('PDF bytes falhou: $e');
      if (!mounted) return;
      setState(() => _pdfError = 'Não foi possível transferir o PDF.');
    }
  }

  void _restorePdfPageIfNeeded() {
    if (_pdfPageRestored || _view != _DigitalView.pdf) return;
    final target = widget.initialPdfPage;
    if (target <= 1) return;
    _pdfPageRestored = true;
    _pdfController.jumpToPage(target);
    _lastSavedPdfPage = target;
    _onPdfPageChanged(target);
  }

  Future<void> _persistPdfProgress() async {
    final page = _pdfController.pageNumber;
    if (page <= 1) return;
    if (page == _lastSavedPdfPage) return;
    _lastSavedPdfPage = page;
    await ReadingProgressHelper.save(_activeBook.id, page, 0);
  }

  Future<void> _registerCompletion() async {
    if (_completionRegistered) return;
    if (!_authController.isAuthenticated) return;
    _completionRegistered = true;
    try {
      final userId = _authController.currentUser!['id'].toString();
      await ReadingProgressHelper.clear(_activeBook.id);
      final gamification =
          await _apiService.incrementBooksRead(userId, bookId: _activeBook.id);
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().applyGamificationResult(gamification);
      }
    } catch (e) {
      debugPrint('Erro ao registar conclusão (digital): $e');
    }
  }

  Future<void> _initEpub() async {
    final url = _activeBook.epubUrl;
    if (url == null || url.isEmpty) return;
    setState(() => _epubError = null);
    try {
      final response = await _mediaDio.get<List<int>>(url);
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw Exception('HTTP $status');
      }
      final data = response.data;
      if (data == null || data.isEmpty) {
        throw Exception('EPUB vazio.');
      }
      final bytes = Uint8List.fromList(data);
      if (!mounted) return;
      setState(() {
        _epubController?.dispose();
        _epubController = EpubController(
          document: EpubDocument.openData(bytes),
        );
        _epubError = null;
      });
    } catch (e) {
      debugPrint('Erro a carregar EPUB: $e');
      if (!mounted) return;
      setState(() => _epubError = 'Não foi possível abrir o EPUB.');
    }
  }

  void _swapToWebViewFallback() {
    final pdfUrl = _activeBook.pdfUrl;
    if (pdfUrl == null || pdfUrl.isEmpty) return;
    setState(() {
      _pdfFallbackToWebView = true;
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.black)
        ..loadRequest(Uri.parse(pdfUrl));
    });
  }

  Future<void> _onPdfLoadFailed(String message) async {
    debugPrint('PDF falhou: $message');
    final url = _activeBook.pdfUrl;
    if (url == null) return;

    if (!_pdfUseMemory && _pdfBytes == null) {
      await _loadPdfBytes(url);
      if (_pdfBytes != null) return;
    }

    if (!_pdfFallbackToWebView && !kIsWeb) {
      _swapToWebViewFallback();
      return;
    }

    if (mounted) {
      setState(() => _pdfError = 'Não foi possível abrir o PDF.');
    }
  }

  Future<void> _handleBack() async {
    if (_view == _DigitalView.pdf) {
      await _persistPdfProgress();
    }
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Get.back();
    }
  }

  void _switchToEpub() {
    final hasEpub =
        _activeBook.epubUrl != null && _activeBook.epubUrl!.isNotEmpty;
    if (!hasEpub) return;
    setState(() => _view = _DigitalView.epub);
    if (_epubController == null) _initEpub();
  }

  void _switchToPdf() {
    final url = _activeBook.pdfUrl;
    if (url == null || url.isEmpty) return;
    setState(() {
      _view = _DigitalView.pdf;
      _pdfDefaultZoomApplied = false;
    });
    if (_pdfBytes == null && !_pdfFallbackToWebView) {
      _preparePdf(url);
    }
  }

  @override
  void dispose() {
    unawaited(ReadingXpService.instance.endSession());
    if (_view == _DigitalView.pdf) {
      _persistPdfProgress();
    }
    _epubController?.dispose();
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = _activeBook;
    final hasPdf = book.pdfUrl != null && book.pdfUrl!.isNotEmpty;
    final hasEpub = book.epubUrl != null && book.epubUrl!.isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _registerCompletion();
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF16213E),
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            book.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              await _registerCompletion();
              await _handleBack();
            },
          ),
          actions: [
            if (hasPdf && hasEpub)
              IconButton(
                tooltip: _view == _DigitalView.pdf ? 'Abrir EPUB' : 'Abrir PDF',
                icon: Icon(
                  _view == _DigitalView.pdf
                      ? Icons.menu_book
                      : Icons.picture_as_pdf,
                ),
                onPressed: _view == _DigitalView.pdf
                    ? _switchToEpub
                    : _switchToPdf,
              ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_view) {
      case _DigitalView.loading:
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      case _DigitalView.pdf:
        return _buildPdf();
      case _DigitalView.epub:
        return _buildEpub();
      case _DigitalView.empty:
        return _buildEmpty();
    }
  }

  Widget _buildPdf() {
    if (_pdfError != null) {
      return _buildPdfError(_pdfError!);
    }

    if (_pdfFallbackToWebView && _webViewController != null) {
      return WebViewWidget(controller: _webViewController!);
    }

    if (_pdfUseMemory && _pdfBytes != null) {
      return _pdfViewer(
        child: SfPdfViewer.memory(
          _pdfBytes!,
          controller: _pdfController,
          initialZoomLevel: _defaultPdfZoom,
          pageLayoutMode: _pdfLayoutMode,
          scrollDirection: _pdfScrollDirection,
          enableDoubleTapZooming: true,
          maxZoomLevel: _pdfMaxZoom,
          canShowScrollHead: false,
          onDocumentLoaded: (_) {
            _applyDefaultPdfZoom();
            _restorePdfPageIfNeeded();
          },
          onPageChanged: (details) {
            _onPdfPageChanged(details.newPageNumber);
          },
          onZoomLevelChanged: (details) {
            if (!mounted) return;
            setState(() => _pdfZoom = details.newZoomLevel);
          },
          onDocumentLoadFailed: (details) {
            _onPdfLoadFailed(details.description);
          },
        ),
      );
    }

    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.windows &&
        _pdfBytes == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final url = _activeBook.pdfUrl!;
    return _pdfViewer(
      child: SfPdfViewer.network(
        url,
        controller: _pdfController,
        initialZoomLevel: _defaultPdfZoom,
        pageLayoutMode: _pdfLayoutMode,
        scrollDirection: _pdfScrollDirection,
        enableDoubleTapZooming: true,
        maxZoomLevel: _pdfMaxZoom,
        canShowScrollHead: false,
        onDocumentLoaded: (_) {
          _applyDefaultPdfZoom();
          _restorePdfPageIfNeeded();
        },
        onPageChanged: (details) {
          _onPdfPageChanged(details.newPageNumber);
        },
        onZoomLevelChanged: (details) {
          if (!mounted) return;
          setState(() => _pdfZoom = details.newZoomLevel);
        },
        onDocumentLoadFailed: (details) {
          _onPdfLoadFailed(details.description);
        },
      ),
    );
  }

  void _onPdfPageChanged(int pageNumber) {
    unawaited(_persistPdfProgress());
    if (!_authController.isAuthenticated || pageNumber < 1) return;
    unawaited(
      ReadingXpService.instance.onPageRead(_activeBook.id, pageNumber - 1),
    );
  }

  Widget _buildPdfError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf,
                color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final url = _activeBook.pdfUrl;
                if (url == null) return;
                setState(() => _pdfError = null);
                _preparePdf(url);
              },
              child: const Text('Tentar novamente'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _handleBack,
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpub() {
    if (_epubError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(
                _epubError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _epubError = null);
                  _initEpub();
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (_epubController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return EpubView(
      controller: _epubController!,
      builders: EpubViewBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(
          textStyle: TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
        ),
        chapterDividerBuilder: (_) => const Divider(color: Colors.white24),
      ),
    );
  }

  Widget _buildEmpty() {
    final message = _loadError ??
        'Este livro digital ainda não tem PDF nem EPUB publicados. '
        'Envie o ficheiro no CMS e publique o livro.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book, color: Colors.white54, size: 56),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 24),
            if (_loadError != null)
              ElevatedButton(
                onPressed: _bootstrap,
                child: const Text('Tentar novamente'),
              ),
            if (_loadError != null) const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _handleBack,
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }
}
