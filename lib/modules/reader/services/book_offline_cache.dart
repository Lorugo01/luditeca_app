import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/models/book_model.dart';
import 'book_image_urls.dart';
import 'book_offline_session.dart';

/// Livro guardado no dispositivo (metadados + ficheiros em disco).
class OfflineBookEntry {
  const OfflineBookEntry({
    required this.id,
    required this.title,
    required this.cachedAt,
    required this.bytes,
    required this.imageCount,
    required this.kind,
  });

  final int id;
  final String title;
  final DateTime cachedAt;
  final int bytes;
  final int imageCount;
  final String kind;

  String get sizeLabel {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class BookOfflinePrepareResult {
  const BookOfflinePrepareResult({
    required this.book,
    required this.urlToLocalPath,
    required this.fromCache,
  });

  final BookModel book;
  final Map<String, String> urlToLocalPath;
  final bool fromCache;
}

/// Cache persistente de livros (JSON + imagens + media) em disco.
class BookOfflineCache {
  BookOfflineCache._();
  static final BookOfflineCache instance = BookOfflineCache._();

  static const _rootFolder = 'luditeca_offline';
  static const _batchSize = 4;

  /// Ilustrações descarregadas antes de abrir o leitor (capa + 1.ª páginas).
  static const _eagerCount = 4;

  /// Livros com download em segundo plano a decorrer.
  final Set<int> _backgroundJobs = {};

  /// Transferências em curso por caminho de destino.
  final Map<String, Future<void>> _inflightFiles = {};

  /// Cliente dedicado a downloads de media (sem token; ficheiros públicos).
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      responseType: ResponseType.bytes,
    ),
  );

  Directory? _rootDir;

  Future<Directory> _root() async {
    if (_rootDir != null) return _rootDir!;
    final base = await getApplicationDocumentsDirectory();
    _rootDir = Directory(p.join(base.path, _rootFolder));
    if (!await _rootDir!.exists()) {
      await _rootDir!.create(recursive: true);
    }
    return _rootDir!;
  }

  Directory _bookDir(Directory root, int bookId) =>
      Directory(p.join(root.path, 'books', '$bookId'));

  File _bookJsonFile(Directory bookDir) => File(p.join(bookDir.path, 'book.json'));

  File _manifestFile(Directory bookDir) =>
      File(p.join(bookDir.path, 'manifest.json'));

  Directory _imagesDir(Directory bookDir) =>
      Directory(p.join(bookDir.path, 'images'));

  Directory _mediaDir(Directory bookDir) =>
      Directory(p.join(bookDir.path, 'media'));

  File _indexFile(Directory root) => File(p.join(root.path, 'index.json'));

  /// Tenta carregar o livro só a partir do disco (sem rede).
  Future<BookModel?> tryLoadBook(int bookId) async {
    try {
      final root = await _root();
      final dir = _bookDir(root, bookId);
      final jsonFile = _bookJsonFile(dir);
      if (!await jsonFile.exists()) return null;

      final manifest = await _readManifest(dir);
      if (manifest == null) return null;

      for (final localRel in manifest.values) {
        final file = File(p.join(dir.path, localRel));
        if (!await file.exists()) return null;
      }

      final raw = jsonDecode(await jsonFile.readAsString());
      if (raw is! Map) return null;
      return BookModel.fromJson(Map<String, dynamic>.from(raw));
    } catch (e) {
      debugPrint('BookOfflineCache.tryLoadBook: $e');
      return null;
    }
  }

  Future<Map<String, String>?> loadUrlMap(int bookId) async {
    final root = await _root();
    final dir = _bookDir(root, bookId);
    final manifest = await _readManifest(dir);
    if (manifest == null) return null;

    final out = <String, String>{};
    for (final entry in manifest.entries) {
      final file = File(p.join(dir.path, entry.value));
      if (await file.exists()) {
        out[entry.key] = file.path;
      }
    }
    return out;
  }

  Future<bool> isBookFullyCached(int bookId) async {
    final book = await tryLoadBook(bookId);
    if (book == null) return false;

    if (book.kind == BookKind.digital) {
      if (book.pdfUrl != null && book.pdfUrl!.isNotEmpty) {
        final pdf = await cachedPdfPath(bookId);
        if (pdf == null) return false;
      }
      final map = await loadUrlMap(bookId);
      if (book.coverImage != null &&
          book.coverImage!.isNotEmpty &&
          (map == null || !map.containsKey(book.coverImage))) {
        return false;
      }
      return true;
    }

    final map = await loadUrlMap(bookId);
    if (map == null) return false;
    final expected = BookImageUrls.fromBook(book);
    if (expected.isEmpty) return true;
    for (final url in expected) {
      if (!map.containsKey(url)) return false;
    }
    return true;
  }

  /// Carrega da cache ou da rede, guarda em disco e devolve paths locais.
  Future<BookOfflinePrepareResult> prepare({
    required BookModel book,
    required Future<BookModel?> Function() fetchFromNetwork,
    void Function(String phaseLabel, double progress)? onProgress,
  }) async {
    onProgress?.call('A verificar conteúdo no dispositivo…', 0.02);

    if (await isBookFullyCached(book.id)) {
      final cached = await tryLoadBook(book.id);
      if (cached == null) {
        // Índice desatualizado; continua para download.
      } else {
      final map = await loadUrlMap(book.id) ?? {};
      onProgress?.call('A abrir do dispositivo…', 1);
      return BookOfflinePrepareResult(
        book: cached,
        urlToLocalPath: map,
        fromCache: true,
      );
      }
    }

    onProgress?.call('A carregar páginas…', 0.08);
    final loaded = await fetchFromNetwork();
    if (loaded == null) {
      throw Exception('Não foi possível carregar o livro.');
    }

    if (loaded.kind == BookKind.digital) {
      await _cacheDigitalBook(loaded, onProgress);
      final map = await loadUrlMap(loaded.id) ?? {};
      final cached = await tryLoadBook(loaded.id) ?? loaded;
      return BookOfflinePrepareResult(
        book: cached,
        urlToLocalPath: map,
        fromCache: false,
      );
    }

    final urls = BookImageUrls.fromBook(loaded);
    if (urls.isEmpty) {
      await _saveBookOnly(loaded);
      onProgress?.call('Livro guardado no dispositivo', 1);
      return BookOfflinePrepareResult(
        book: loaded,
        urlToLocalPath: const {},
        fromCache: false,
      );
    }

    final root = await _root();
    final dir = _bookDir(root, loaded.id);
    final imagesDir = _imagesDir(dir);
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    // Só as primeiras ilustrações bloqueiam a abertura do leitor; o resto
    // descarrega em segundo plano (páginas de PPTX podem ter GIFs de 40 MB).
    final eager = urls.take(_eagerCount).toList();
    final rest = urls.skip(_eagerCount).toList();

    final urlToRel = <String, String>{};
    final total = urls.length;
    onProgress?.call('A guardar ilustrações (0/$total)…', 0.12);

    await _downloadBatches(
      urls: eager,
      imagesDir: imagesDir,
      urlToRel: urlToRel,
      onBatchDone: (done) => onProgress?.call(
        'A guardar ilustrações ($done/$total)…',
        0.12 + (done / eager.length) * 0.82,
      ),
    );

    // Manifesto parcial: se a app fechar a meio, a próxima abertura retoma
    // (ficheiros já existentes são reaproveitados).
    await _writeManifest(dir, urlToRel);
    await _saveBookJson(dir, loaded);
    await _updateIndex(loaded, urlToRel.length);

    if (rest.isNotEmpty) {
      _startBackgroundDownload(
        book: loaded,
        dir: dir,
        imagesDir: imagesDir,
        urls: rest,
        urlToRel: urlToRel,
      );
    }

    final localPaths = <String, String>{};
    for (final e in urlToRel.entries) {
      localPaths[e.key] = p.join(dir.path, e.value);
    }

    onProgress?.call(
      rest.isEmpty ? 'Pronto para ler offline' : 'A abrir o livro…',
      1,
    );

    return BookOfflinePrepareResult(
      book: loaded,
      urlToLocalPath: localPaths,
      fromCache: false,
    );
  }

  Future<void> _downloadBatches({
    required List<String> urls,
    required Directory imagesDir,
    required Map<String, String> urlToRel,
    void Function(int done)? onBatchDone,
    void Function(String url, String rel)? onFile,
  }) async {
    for (var i = 0; i < urls.length; i += _batchSize) {
      final end = (i + _batchSize < urls.length) ? i + _batchSize : urls.length;
      final batch = urls.sublist(i, end);
      await Future.wait(batch.map((url) async {
        try {
          final rel = await _downloadToBook(
            url: url,
            imagesDir: imagesDir,
            urlToRel: urlToRel,
          );
          onFile?.call(url, rel);
        } catch (e) {
          debugPrint('BookOfflineCache: falha $url — $e');
        }
      }));
      onBatchDone?.call(end);
    }
  }

  /// Continua o download das restantes ilustrações sem bloquear a leitura.
  /// Cada ficheiro concluído passa a ser servido do disco na sessão activa.
  void _startBackgroundDownload({
    required BookModel book,
    required Directory dir,
    required Directory imagesDir,
    required List<String> urls,
    required Map<String, String> urlToRel,
  }) {
    if (_backgroundJobs.contains(book.id)) return;
    _backgroundJobs.add(book.id);

    Future<void>(() async {
      try {
        await _downloadBatches(
          urls: urls,
          imagesDir: imagesDir,
          urlToRel: urlToRel,
          onFile: (url, rel) => BookOfflineSession.register(
            book.id,
            url,
            p.join(dir.path, rel),
          ),
        );
        await _writeManifest(dir, urlToRel);
        await _updateIndex(book, urlToRel.length);
      } catch (e) {
        debugPrint('BookOfflineCache: download em segundo plano falhou — $e');
      } finally {
        _backgroundJobs.remove(book.id);
      }
    });
  }

  Future<void> _cacheDigitalBook(
    BookModel book,
    void Function(String, double)? onProgress,
  ) async {
    final root = await _root();
    final dir = _bookDir(root, book.id);
    final mediaDir = _mediaDir(dir);
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final urlToRel = <String, String>{};

    if (book.pdfUrl != null && book.pdfUrl!.isNotEmpty) {
      onProgress?.call('A guardar PDF…', 0.3);
      final dest = File(p.join(mediaDir.path, 'book.pdf'));
      await _downloadUrlToFile(book.pdfUrl!, dest);
      urlToRel[book.pdfUrl!] = p.relative(dest.path, from: dir.path);
    }

    if (book.coverImage != null && book.coverImage!.isNotEmpty) {
      onProgress?.call('A guardar capa…', 0.6);
      final imagesDir = _imagesDir(dir);
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      await _downloadToBook(
        url: book.coverImage!,
        imagesDir: imagesDir,
        urlToRel: urlToRel,
      );
    }

    await _writeManifest(dir, urlToRel);
    await _saveBookJson(dir, book);
    await _updateIndex(book, urlToRel.length);
    onProgress?.call('Livro digital guardado', 1);
  }

  Future<void> _saveBookOnly(BookModel book) async {
    final root = await _root();
    final dir = _bookDir(root, book.id);
    await _writeManifest(dir, {});
    await _saveBookJson(dir, book);
    await _updateIndex(book, 0);
  }

  Future<String> _downloadToBook({
    required String url,
    required Directory imagesDir,
    required Map<String, String> urlToRel,
  }) async {
    final name = _fileNameForUrl(url);
    final dest = File(p.join(imagesDir.path, name));
    if (await dest.exists()) {
      final rel = p.join('images', name);
      urlToRel[url] = rel;
      return rel;
    }
    // Mesmo ficheiro pedido em paralelo (ex.: reabrir o livro com o download
    // em segundo plano a decorrer) partilha a mesma transferência.
    final inflight = _inflightFiles[dest.path];
    if (inflight != null) {
      await inflight;
    } else {
      final job = _downloadUrlToFile(url, dest);
      _inflightFiles[dest.path] = job;
      try {
        await job;
      } finally {
        _inflightFiles.remove(dest.path);
      }
    }
    final rel = p.join('images', name);
    urlToRel[url] = rel;
    return rel;
  }

  /// Descarrega em stream para um ficheiro temporário e só depois renomeia:
  /// evita ter o ficheiro inteiro (até dezenas de MB) em memória e nunca deixa
  /// ficheiros truncados com o nome final se a app fechar a meio.
  Future<void> _downloadUrlToFile(String url, File dest) async {
    if (!await dest.parent.exists()) {
      await dest.parent.create(recursive: true);
    }
    final tmp = File('${dest.path}.part');
    try {
      final response = await _dio.download(url, tmp.path);
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        throw Exception('HTTP $status');
      }
      if (!await tmp.exists() || await tmp.length() == 0) {
        throw Exception('Resposta vazia ao transferir $url');
      }
      await tmp.rename(dest.path);
    } finally {
      if (await tmp.exists()) {
        await tmp.delete();
      }
    }
  }

  String _fileNameForUrl(String url) {
    final uri = Uri.tryParse(url);
    var seg = '';
    if (uri != null && uri.pathSegments.isNotEmpty) {
      seg = uri.pathSegments.last;
    }
    final safeSeg = seg.replaceAll(RegExp(r'[^\w.\-]'), '_');
    final hash = url.hashCode.abs();
    if (safeSeg.contains('.')) {
      return '${hash}_$safeSeg';
    }
    return '$hash.img';
  }

  Future<void> _saveBookJson(Directory bookDir, BookModel book) async {
    if (!await bookDir.exists()) {
      await bookDir.create(recursive: true);
    }
    await _bookJsonFile(bookDir).writeAsString(
      jsonEncode(book.toJson()),
      flush: true,
    );
  }

  Future<Map<String, String>?> _readManifest(Directory bookDir) async {
    final file = _manifestFile(bookDir);
    if (!await file.exists()) return null;
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map) return null;
      return raw.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeManifest(
    Directory bookDir,
    Map<String, String> urlToRel,
  ) async {
    if (!await bookDir.exists()) {
      await bookDir.create(recursive: true);
    }
    await _manifestFile(bookDir).writeAsString(
      jsonEncode(urlToRel),
      flush: true,
    );
  }

  Future<void> _updateIndex(BookModel book, int imageCount) async {
    final root = await _root();
    final dir = _bookDir(root, book.id);
    final bytes = await _folderSize(dir);
    final entries = await listEntries();
    final others = entries.where((e) => e.id != book.id).toList();
    others.add(
      OfflineBookEntry(
        id: book.id,
        title: book.title,
        cachedAt: DateTime.now(),
        bytes: bytes,
        imageCount: imageCount,
        kind: book.kind.name,
      ),
    );
    others.sort((a, b) => b.cachedAt.compareTo(a.cachedAt));
    await _indexFile(root).writeAsString(
      jsonEncode({
        'books': others
            .map(
              (e) => {
                'id': e.id,
                'title': e.title,
                'cached_at': e.cachedAt.toIso8601String(),
                'bytes': e.bytes,
                'image_count': e.imageCount,
                'kind': e.kind,
              },
            )
            .toList(),
      }),
      flush: true,
    );
  }

  Future<List<OfflineBookEntry>> listEntries() async {
    try {
      final root = await _root();
      final file = _indexFile(root);
      if (!await file.exists()) return [];
      final raw = jsonDecode(await file.readAsString());
      if (raw is! Map || raw['books'] is! List) return [];
      return (raw['books'] as List).whereType<Map>().map((m) {
        return OfflineBookEntry(
          id: m['id'] is int
              ? m['id'] as int
              : int.tryParse('${m['id']}') ?? 0,
          title: '${m['title'] ?? 'Livro'}',
          cachedAt: DateTime.tryParse('${m['cached_at']}') ?? DateTime.now(),
          bytes: m['bytes'] is int
              ? m['bytes'] as int
              : int.tryParse('${m['bytes']}') ?? 0,
          imageCount: m['image_count'] is int
              ? m['image_count'] as int
              : int.tryParse('${m['image_count']}') ?? 0,
          kind: '${m['kind'] ?? 'legacy'}',
        );
      }).toList();
    } catch (e) {
      debugPrint('BookOfflineCache.listEntries: $e');
      return [];
    }
  }

  Future<int> totalBytes() async {
    final entries = await listEntries();
    return entries.fold<int>(0, (sum, e) => sum + e.bytes);
  }

  Future<void> removeBook(int bookId) async {
    final root = await _root();
    final dir = _bookDir(root, bookId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    final entries = await listEntries();
    final kept = entries.where((e) => e.id != bookId).toList();
    await _indexFile(root).writeAsString(
      jsonEncode({
        'books': kept
            .map(
              (e) => {
                'id': e.id,
                'title': e.title,
                'cached_at': e.cachedAt.toIso8601String(),
                'bytes': e.bytes,
                'image_count': e.imageCount,
                'kind': e.kind,
              },
            )
            .toList(),
      }),
      flush: true,
    );
    if (BookOfflineSession.activeBookId == bookId) {
      BookOfflineSession.clear();
    }
  }

  Future<void> clearAllBooks() async {
    final root = await _root();
    final booksRoot = Directory(p.join(root.path, 'books'));
    if (await booksRoot.exists()) {
      await booksRoot.delete(recursive: true);
    }
    await _indexFile(root).writeAsString('{"books":[]}', flush: true);
    BookOfflineSession.clear();
  }

  Future<int> _folderSize(Directory dir) async {
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  /// Path local do PDF em cache, se existir.
  Future<String?> cachedPdfPath(int bookId) async {
    final root = await _root();
    final file = File(
      p.join(_bookDir(root, bookId).path, 'media', 'book.pdf'),
    );
    if (await file.exists()) return file.path;
    return null;
  }
}
