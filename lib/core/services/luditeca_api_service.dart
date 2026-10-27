import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../config/dev_api_resolver.dart';
import '../utils/media_url.dart';

/// Cliente HTTP da API Luditeca (VPS). Substitui o antigo LuditecaApiService.
class LuditecaApiService {
  static final LuditecaApiService _instance = LuditecaApiService._internal();
  bool _isInitialized = false;
  String? _token;
  Map<String, dynamic>? _currentUser;

  factory LuditecaApiService() {
    return _instance;
  }

  LuditecaApiService._internal();

  String get _baseUrl => DevApiResolver.apiBaseUrl.replaceAll(RegExp(r'\/+$'), '');
  String get mediaBaseUrl =>
      DevApiResolver.mediaBaseUrl.replaceAll(RegExp(r'\/+$'), '');

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  Map<String, dynamic>? get currentUser => _currentUser;

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  /// Cliente HTTP único: timeouts globais + injeção automática do token.
  late final Dio _dio = _createDio();

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
        responseType: ResponseType.json,
        // Erros são tratados manualmente para mensagens amigáveis.
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final withAuth = options.extra['withAuth'] != false;
          if (withAuth && isAuthenticated) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
      ),
    );
    return dio;
  }

  String _absoluteUrl(String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$_baseUrl$normalizedPath';
  }

  String _dioErrorMessage(DioException e, String method, String path) {
    final data = e.response?.data;
    if (data is Map && data['error'] != null) {
      return '${data['error']}';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tempo de ligação esgotado. Verifique a sua internet.';
      case DioExceptionType.connectionError:
        return 'Não foi possível ligar ao servidor.';
      default:
        final code = e.response?.statusCode;
        return 'Falha na requisição ($method $path)'
            '${code != null ? ': $code' : ''}';
    }
  }

  Future<Response<dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool withAuth = true,
  }) async {
    try {
      return await _dio.request<dynamic>(
        _absoluteUrl(path),
        data: body,
        queryParameters: query,
        options: Options(
          method: method.toUpperCase(),
          extra: {'withAuth': withAuth},
        ),
      );
    } on DioException catch (e) {
      throw Exception(_dioErrorMessage(e, method, path));
    }
  }

  Future<Map<String, dynamic>> _requestJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool withAuth = true,
  }) async {
    final response = await _send(
      method,
      path,
      body: body,
      query: query,
      withAuth: withAuth,
    );
    final data = response.data;
    if (data == null || (data is String && data.isEmpty)) {
      return <String, dynamic>{};
    }
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {'data': data};
  }

  Future<List<dynamic>> _requestList(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool withAuth = true,
  }) async {
    final response = await _send(
      method,
      path,
      body: body,
      query: query,
      withAuth: withAuth,
    );
    final data = response.data;
    if (data is List) return data;
    if (data is Map && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }
    return <dynamic>[];
  }

  String _ensureAbsoluteMediaUrl(
    String? raw, {
    String defaultBucket = 'pages',
  }) {
    return resolveMediaUrl(raw, mediaBaseUrl, defaultBucket: defaultBucket) ??
        (raw ?? '').trim();
  }

  Map<String, dynamic> _normalizeBook(Map<String, dynamic> raw) {
    final item = Map<String, dynamic>.from(raw);
    item['id'] = int.tryParse('${item['id']}') ?? 0;
    item['author_id'] = item['author_id'] != null ? int.tryParse('${item['author_id']}') : null;
    item['category_id'] = item['category_id'] != null
        ? (int.tryParse('${item['category_id']}') ?? 0)
        : 0;

    final createdAt = item['created_at'] ?? item['createdAt'];
    item['created_at'] = createdAt?.toString() ?? DateTime.now().toIso8601String();

    // Compat de camelCase → snake_case dos campos novos do backend.
    if (item['bookType'] != null && item['book_type'] == null) {
      item['book_type'] = item['bookType'];
    }
    if (item['pdfUrl'] != null && item['pdf_url'] == null) {
      item['pdf_url'] = item['pdfUrl'];
    }
    if (item['epubUrl'] != null && item['epub_url'] == null) {
      item['epub_url'] = item['epubUrl'];
    }
    if (item['soundtrackUrl'] != null && item['soundtrack_url'] == null) {
      item['soundtrack_url'] = item['soundtrackUrl'];
    }
    if (item['bookQuiz'] != null && item['book_quiz'] == null) {
      item['book_quiz'] = item['bookQuiz'];
    }
    if (item['isPdf'] != null && item['is_pdf'] == null) {
      item['is_pdf'] = item['isPdf'];
    }
    if (item['coverImage'] != null && item['cover_image'] == null) {
      item['cover_image'] = item['coverImage'];
    }
    if (item['ageRange'] != null && item['age_range'] == null) {
      item['age_range'] = item['ageRange'];
    }

    final coverImage = item['cover_image']?.toString();
    if (coverImage != null && coverImage.isNotEmpty) {
      item['cover_image'] = _ensureAbsoluteMediaUrl(
        coverImage,
        defaultBucket: 'covers',
      );
    }

    // PNG 400×300 do 1.º frame, gerado no upload. A capa original pode ser
    // um GIF de vários MB e só é usada na ficha do livro.
    final coverThumb = (item['cover_thumb_url'] ?? item['coverThumbUrl'])?.toString();
    item['cover_thumb_url'] = coverThumb != null && coverThumb.trim().isNotEmpty
        ? _ensureAbsoluteMediaUrl(coverThumb, defaultBucket: 'covers')
        : null;

    final pdfUrl = item['pdf_url']?.toString();
    if (pdfUrl != null && pdfUrl.isNotEmpty) {
      item['pdf_url'] = _ensureAbsoluteMediaUrl(pdfUrl, defaultBucket: 'pages');
    }

    final epubUrl = item['epub_url']?.toString();
    if (epubUrl != null && epubUrl.isNotEmpty) {
      item['epub_url'] = _ensureAbsoluteMediaUrl(epubUrl, defaultBucket: 'pages');
    }

    final soundtrack = item['soundtrack_url']?.toString();
    if (soundtrack != null && soundtrack.isNotEmpty) {
      item['soundtrack_url'] = _ensureAbsoluteMediaUrl(
        soundtrack,
        defaultBucket: 'audios',
      );
    }

    if (item['authors'] is Map<String, dynamic>) {
      final authors = Map<String, dynamic>.from(item['authors'] as Map<String, dynamic>);
      if (authors['photo_url'] != null) {
        authors['photo_url'] = _ensureAbsoluteMediaUrl(
          '${authors['photo_url']}',
          defaultBucket: 'autores',
        );
      }
      item['authors'] = authors;
    }

    final pages = item['pages'];
    if (pages is List) {
      item['pages'] = pages.map((page) {
        if (page is! Map) return page;
        final p = Map<String, dynamic>.from(page);
        final img = p['image_url'] ?? p['imageUrl'];
        if (img != null && '$img'.trim().isNotEmpty) {
          p['image_url'] = _ensureAbsoluteMediaUrl('$img', defaultBucket: 'pages');
        }
        final narration = p['narration_url'] ?? p['narrationUrl'];
        if (narration != null && '$narration'.trim().isNotEmpty) {
          p['narration_url'] = _ensureAbsoluteMediaUrl(
            '$narration',
            defaultBucket: 'audios',
          );
        }
        return p;
      }).toList();
    }

    return item;
  }

  /// Persiste o estado da aventura interactiva (formato espelhado de
  /// `interactiveAdventure.js`, chave `luditeca-adventure-<bookId>`).
  Future<void> persistAdventureRun(
    String bookId,
    Map<String, dynamic> state,
  ) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(
        'luditeca-adventure-$bookId',
        jsonEncode(state),
      );
    } catch (_) {
      // Falhas locais não devem partir a leitura — o leitor mantém o estado em memória.
    }
  }

  Future<Map<String, dynamic>?> loadAdventureRun(String bookId) async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString('luditeca-adventure-$bookId');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAdventureRun(String bookId) async {
    try {
      final prefs = await _prefs;
      await prefs.remove('luditeca-adventure-$bookId');
    } catch (_) {}
  }

  Future<void> _persistSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    _token = token;
    _currentUser = user;
    final prefs = await _prefs;
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_user', jsonEncode(user));
  }

  Future<void> _clearSession() async {
    _token = null;
    _currentUser = null;
    invalidateBooksCache();
    _bookDetailCache.clear();
    final prefs = await _prefs;
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    await DevApiResolver.resolveIfNeeded();
    final prefs = await _prefs;
    // Limpeza única de lixo antigo: os detalhes gravavam `pages.toString()`
    // (não-JSON, nunca lido) em `book_pages_<id>`, inflacionando as prefs.
    for (final key in prefs.getKeys().where((k) => k.startsWith('book_pages_'))) {
      await prefs.remove(key);
    }
    _token = prefs.getString('auth_token');
    final rawUser = prefs.getString('auth_user');
    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        _currentUser = Map<String, dynamic>.from(jsonDecode(rawUser));
      } catch (_) {
        _currentUser = null;
      }
    }

    if (_token != null && _token!.isNotEmpty) {
      try {
        final me = await _requestJson('GET', '/auth/me');
        final user = me['user'] as Map<String, dynamic>?;
        if (user != null) {
          _currentUser = user;
          await prefs.setString('auth_user', jsonEncode(user));
        }
      } catch (_) {
        await _clearSession();
      }
    }

    _isInitialized = true;
  }

  Future<Map<String, dynamic>> signUp(String email, String password) async {
    if (!_isInitialized) await initialize();
    final response = await _requestJson(
      'POST',
      '/auth/register',
      body: {'email': email, 'password': password},
      withAuth: false,
    );
    final token = response['access_token']?.toString();
    final user = response['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(response['user'] as Map<String, dynamic>)
        : null;
    if (token == null || user == null) {
      throw Exception('Resposta de registro inválida.');
    }
    await _persistSession(token: token, user: user);
    return {'user': user, 'session': {'access_token': token}};
  }

  Future<Map<String, dynamic>> signIn(String email, String password) async {
    if (!_isInitialized) await initialize();
    final response = await _requestJson(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
      withAuth: false,
    );
    final token = response['access_token']?.toString();
    final user = response['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(response['user'] as Map<String, dynamic>)
        : null;
    if (token == null || user == null) {
      throw Exception('Resposta de login inválida.');
    }
    await _persistSession(token: token, user: user);
    return {'user': user, 'session': {'access_token': token}};
  }

  Future<void> signOut() async {
    await _clearSession();
  }

  Map<String, dynamic>? getCurrentUser() => _currentUser;

  Future<Map<String, dynamic>> signInWithToken(String token) async {
    if (!_isInitialized) await initialize();
    _token = token;
    final me = await _requestJson('GET', '/auth/me');
    final user = me['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(me['user'] as Map<String, dynamic>)
        : null;
    if (user == null) {
      throw Exception('Token inválido.');
    }
    await _persistSession(token: token, user: user);
    return {'user': user, 'session': {'access_token': token}};
  }

  /// Catálogo em memória: Home, Biblioteca, categorias, favoritos e histórico
  /// partilham a mesma lista em vez de cada ecrã pedir `/books` de novo.
  static const Duration _booksCacheTtl = Duration(minutes: 3);
  static const int _booksPageSize = 100;
  List<Map<String, dynamic>>? _booksCache;
  DateTime? _booksCacheAt;
  Future<List<Map<String, dynamic>>>? _booksInflight;

  /// Lista de livros (cartões, sem páginas). Usa cache em memória; pedidos
  /// simultâneos partilham a mesma chamada. [forceRefresh] ignora a cache.
  Future<List<Map<String, dynamic>>> getBooks({bool forceRefresh = false}) {
    final cached = _booksCache;
    final at = _booksCacheAt;
    if (!forceRefresh &&
        cached != null &&
        at != null &&
        DateTime.now().difference(at) < _booksCacheTtl) {
      return Future.value(_copyBooks(cached));
    }
    final inflight = _booksInflight;
    if (inflight != null) return inflight.then(_copyBooks);

    final job = _fetchAllBooks();
    _booksInflight = job;
    return job.then((books) {
      _booksCache = books;
      _booksCacheAt = DateTime.now();
      return _copyBooks(books);
    }).whenComplete(() => _booksInflight = null);
  }

  void invalidateBooksCache() {
    _booksCache = null;
    _booksCacheAt = null;
  }

  /// Cópia rasa por livro: os ecrãs podem mutar os mapas sem afectar a cache.
  List<Map<String, dynamic>> _copyBooks(List<Map<String, dynamic>> books) =>
      books.map((b) => Map<String, dynamic>.from(b)).toList();

  /// `GET /books` é paginado (máx. 100 por página); percorre todas as páginas.
  Future<List<Map<String, dynamic>>> _fetchAllBooks() async {
    if (!_isInitialized) await initialize();
    final out = <Map<String, dynamic>>[];
    var offset = 0;
    while (true) {
      final response = await _requestJson(
        'GET',
        '/books',
        query: {'limit': '$_booksPageSize', 'offset': '$offset'},
      );
      final data = response['data'];
      final page = data is List ? data : const <dynamic>[];
      out.addAll(
        page
            .whereType<Map>()
            .map((e) => _normalizeBook(Map<String, dynamic>.from(e))),
      );
      final total = int.tryParse('${response['total']}');
      offset += page.length;
      if (page.length < _booksPageSize || total == null || offset >= total) {
        break;
      }
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> getBooksByCategory(int categoryId) async {
    final books = await getBooks();
    return books.where((b) => b['category_id'] == categoryId).toList();
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    if (!_isInitialized) await initialize();
    final response = await _requestList('GET', '/categories');
    return response.whereType<Map>().map((raw) {
      final item = Map<String, dynamic>.from(raw);
      item['id'] = int.tryParse('${item['id']}') ?? 0;
      final imageUrl = item['image_url'] ?? item['imageUrl'];
      item['image_url'] = _ensureAbsoluteMediaUrl(
        imageUrl?.toString(),
        defaultBucket: 'categories',
      );
      final createdAt = item['created_at'] ?? item['createdAt'];
      item['created_at'] = createdAt?.toString() ?? DateTime.now().toIso8601String();
      return item;
    }).toList();
  }

  /// Livros completos (com páginas) recentes: a pré-carga nos detalhes e o
  /// leitor partilham o mesmo pedido em vez de descarregar o livro duas vezes.
  static const Duration _bookDetailTtl = Duration(minutes: 2);
  static const int _bookDetailMax = 3;
  final Map<String, ({DateTime at, Map<String, dynamic> book})> _bookDetailCache =
      {};
  final Map<String, Future<Map<String, dynamic>>> _bookDetailInflight = {};

  Future<Map<String, dynamic>?> getBookById(String bookId) async {
    final hit = _bookDetailCache[bookId];
    if (hit != null && DateTime.now().difference(hit.at) < _bookDetailTtl) {
      return Map<String, dynamic>.from(hit.book);
    }
    final job = _bookDetailInflight.putIfAbsent(bookId, () async {
      try {
        if (!_isInitialized) await initialize();
        final response = await _requestJson('GET', '/books/$bookId');
        final book = _normalizeBook(response);
        _bookDetailCache.remove(bookId);
        _bookDetailCache[bookId] = (at: DateTime.now(), book: book);
        while (_bookDetailCache.length > _bookDetailMax) {
          _bookDetailCache.remove(_bookDetailCache.keys.first);
        }
        return book;
      } finally {
        _bookDetailInflight.remove(bookId);
      }
    });
    return Map<String, dynamic>.from(await job);
  }

  /// Aquece a cache do livro completo sem bloquear a UI (ex.: nos detalhes,
  /// antes de o utilizador tocar em «Ler»).
  void prefetchBook(String bookId) {
    getBookById(bookId).catchError((Object e) {
      debugPrint('Pré-carga do livro $bookId falhou: $e');
      return null;
    });
  }

  /// Devolve `null` se o livro não existir (404), em vez de lançar excepção.
  Future<Map<String, dynamic>?> tryGetBookById(String bookId) async {
    try {
      return await getBookById(bookId);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('não encontrado') ||
          msg.contains('nao encontrado') ||
          msg.contains('not found') ||
          msg.contains(': 404')) {
        return null;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    if (!_isInitialized) await initialize();
    if (!isAuthenticated) return null;
    final response = await _requestJson('GET', '/me/profile');
    final profile = response['profile'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(response['profile'] as Map<String, dynamic>)
        : <String, dynamic>{};
    profile['id'] = _currentUser?['id'] ?? userId;
    return profile;
  }

  Future<bool> updateReadingProgress(
    String userId,
    String bookId,
    int pageIndex,
    int stepIndex,
  ) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return false;
      final progress = profile['progress'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(profile['progress'] as Map<String, dynamic>)
          : <String, dynamic>{};
      progress[bookId] = {'page': pageIndex, 'step': stepIndex};

      await _requestJson(
        'PATCH',
        '/me/profile',
        body: {'progress': progress},
      );
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar progresso: $e');
      return false;
    }
  }

  Future<bool> removeBookFromProgress(String userId, String bookId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return false;
      final progress = profile['progress'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(profile['progress'] as Map<String, dynamic>)
          : <String, dynamic>{};
      progress.remove(bookId);
      await _requestJson('PATCH', '/me/profile', body: {'progress': progress});
      return true;
    } catch (e) {
      debugPrint('Erro ao remover livro do progresso: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getBooksInProgress(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return [];
      final progress = profile['progress'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(profile['progress'] as Map<String, dynamic>)
          : <String, dynamic>{};
      if (progress.isEmpty) return [];

      // Cartões vêm do catálogo em cache (uma chamada), não de N pedidos
      // sequenciais a `/books/:id` com todas as páginas de cada livro.
      final catalog = <String, Map<String, dynamic>>{
        for (final b in await getBooks()) '${b['id']}': b,
      };

      final List<Map<String, dynamic>> booksInProgress = [];
      final staleBookIds = <String>[];
      final missing = <MapEntry<String, List<int>>>[];

      for (final entry in progress.entries) {
        if (_isXpMetaProgressKey(entry.key.toString())) continue;
        final raw = entry.value;
        if (raw is! Map) continue;

        final page = _progressAsInt(raw['page']);
        final step = _progressAsInt(raw['step']);
        if (page <= 0 && step <= 0) continue;

        final bookId = entry.key.toString();
        final card = catalog[bookId];
        if (card != null) {
          booksInProgress.add({
            ...card,
            'saved_page': page,
            'saved_step': step,
          });
        } else {
          missing.add(MapEntry(bookId, [page, step]));
        }
      }

      // Só confirma (em paralelo) os que não estão no catálogo — livro
      // apagado vs. catálogo desactualizado.
      await Future.wait(missing.map((m) async {
        try {
          final bookData = await tryGetBookById(m.key);
          if (bookData != null) {
            booksInProgress.add({
              ...bookData,
              'saved_page': m.value[0],
              'saved_step': m.value[1],
            });
          } else {
            staleBookIds.add(m.key);
          }
        } catch (e) {
          debugPrint('Progresso: livro ${m.key} ignorado ($e)');
        }
      }));

      if (staleBookIds.isNotEmpty) {
        await _removeStaleProgressEntries(userId, staleBookIds);
      }

      return booksInProgress;
    } catch (e) {
      debugPrint('Erro ao buscar livros em progresso: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> incrementBooksRead(
    String userId, {
    required int bookId,
  }) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return null;

      int currentBooksRead = int.tryParse('${profile['books_read'] ?? 0}') ?? 0;
      final List<dynamic> history = profile['books_read_history'] is List
          ? List<dynamic>.from(profile['books_read_history'] as List)
          : <dynamic>[];
      if (!history.contains(bookId)) {
        history.add(bookId);
      }

      return await _requestJson(
        'PATCH',
        '/me/profile',
        body: {
          'books_read': currentBooksRead + 1,
          'books_read_history': history,
        },
      );
    } catch (e) {
      debugPrint('Erro ao incrementar books_read: $e');
      return null;
    }
  }

  static const String _xpMetaProgressKey = '__xp_meta';

  bool _isXpMetaProgressKey(String bookId) =>
      bookId == _xpMetaProgressKey || bookId.startsWith('__');

  /// Lista conquistas com progresso e sincroniza desbloqueios no servidor.
  Future<Map<String, dynamic>?> getAchievements() async {
    if (!isAuthenticated) return null;
    try {
      return await _requestJson('GET', '/me/profile/achievements');
    } catch (e) {
      debugPrint('Erro ao carregar conquistas: $e');
      return null;
    }
  }

  /// Atribui XP por páginas lidas (30 cada) e/ou tempo de leitura (30 por hora).
  Future<Map<String, dynamic>?> awardReadingXp({
    List<Map<String, dynamic>>? pages,
    int? readingSeconds,
  }) async {
    if (!isAuthenticated) return null;
    final body = <String, dynamic>{};
    if (pages != null && pages.isNotEmpty) {
      body['pages'] = pages;
    }
    if (readingSeconds != null && readingSeconds > 0) {
      body['reading_seconds'] = readingSeconds;
    }
    if (body.isEmpty) return null;

    try {
      final response = await _requestJson('POST', '/me/profile/award-xp', body: body);
      return response;
    } catch (e) {
      debugPrint('Erro ao atribuir XP de leitura: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateMyProfile({
    required String name,
    String? iconeUrl,
    int? age,
    String? avatarId,
    int? xpTotal,
    int? xpBalance,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (iconeUrl != null) 'icone': iconeUrl,
      if (age != null) 'age': age,
      if (avatarId != null) 'avatar_id': avatarId,
      if (xpTotal != null) 'xp_total': xpTotal,
      if (xpBalance != null) 'xp_balance': xpBalance,
    };
    await _requestJson('PATCH', '/me/profile', body: body);
    final response = await _requestJson('GET', '/me/profile');
    return Map<String, dynamic>.from(response['profile'] as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getFavoriteBooks() async {
    final response = await _requestList('GET', '/me/favorites/books');
    return response
        .whereType<Map>()
        .map((e) => _normalizeBook(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> setFavorites(List<int> favoriteIds) async {
    return await _requestJson(
      'PATCH',
      '/me/profile',
      body: {'favorites': favoriteIds},
    );
  }

  Future<String> uploadAvatar({
    required List<int> bytes,
    required String fileName,
  }) async {
    if (!isAuthenticated) throw Exception('Usuário não autenticado.');

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    try {
      final response = await _dio.post<dynamic>(
        _absoluteUrl('/media/upload'),
        queryParameters: const {'mediaType': 'avatar', 'root': 'profile'},
        data: formData,
      );
      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : <String, dynamic>{};
      final payload = data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : <String, dynamic>{};
      final url = payload['url']?.toString();
      if (url == null || url.isEmpty) {
        throw Exception('Upload concluído sem URL de retorno.');
      }
      return url;
    } on DioException catch (e) {
      throw Exception(_dioErrorMessage(e, 'POST', '/media/upload'));
    }
  }

  Future<List<Map<String, dynamic>>> fetchBooksByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final books = await getBooks();
    final target = ids.toSet();
    return books.where((book) => target.contains(book['id'])).toList();
  }

  Future<int> getInProgressBooksCount(String userId) async {
    final profile = await getUserProfile(userId);
    if (profile == null) return 0;
    final progress = profile['progress'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(profile['progress'] as Map<String, dynamic>)
        : <String, dynamic>{};
    return progress.length;
  }

  /// Compatibilidade de assinatura para código legado do app.
  Future<Map<String, dynamic>?> getBook(String id) async {
    return getBookById(id);
  }

  static int _progressAsInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  Future<void> _removeStaleProgressEntries(
    String userId,
    List<String> bookIds,
  ) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return;
      final progress = profile['progress'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(profile['progress'] as Map<String, dynamic>)
          : <String, dynamic>{};
      var changed = false;
      for (final id in bookIds) {
        if (progress.remove(id) != null) changed = true;
      }
      if (!changed) return;
      await _requestJson('PATCH', '/me/profile', body: {'progress': progress});
    } catch (e) {
      debugPrint('Erro ao limpar progresso obsoleto: $e');
    }
  }
}
