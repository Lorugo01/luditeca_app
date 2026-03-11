import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient client;
  bool _isInitialized = false;

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Verifica se o Supabase já está inicializado
      try {
        client = Supabase.instance.client;
        _isInitialized = true;
        return;
      } catch (_) {}

      await Supabase.initialize(
        url: 'https://wyrzhjomcvdokocanpjv.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind5cnpoam9tY3Zkb2tvY2FucGp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ1NDg3MzgsImV4cCI6MjA2MDEyNDczOH0.ofu0BEodxmdzFN9y5wkYakZxw8LPLja72NOhbTXLelk',
      );
      client = Supabase.instance.client;
      _isInitialized = true;
    } catch (_) {}
  }

  // Métodos de autenticação
  Future<AuthResponse> signUp(String email, String password) async {
    if (!_isInitialized) await initialize();

    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> signIn(String email, String password) async {
    if (!_isInitialized) await initialize();

    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    if (!_isInitialized) await initialize();

    await client.auth.signOut();
  }

  User? getCurrentUser() {
    if (!_isInitialized) return null;
    return client.auth.currentUser;
  }

  Stream<AuthState> authStateChanges() {
    if (!_isInitialized) return Stream.empty();
    return client.auth.onAuthStateChange;
  }

  // Funções para livros
  Future<List<Map<String, dynamic>>> getBooks() async {
    if (!_isInitialized) await initialize();

    try {
      final response = await client
          .from('books')
          .select('''
            *,
            authors!author_id (
              id,
              name,
              bio,
              photo_url
            ),
            categories!category_id (
              id,
              name,
              image_url
            )
          ''')
          .order('created_at', ascending: false);

      return _processImageUrls(response, false);
    } catch (e) {
      return [];
    }
  }

  // Processa URLs de imagens para o formato completo
  List<Map<String, dynamic>> _processImageUrls(
    List<Map<String, dynamic>> data,
    bool isPortuguese,
  ) {
    return data.map((item) {
      final processedItem = Map<String, dynamic>.from(item);
      final imageUrl = processedItem['cover_image']?.toString() ?? '';

      if (imageUrl.isNotEmpty &&
          !(imageUrl.startsWith('http://') ||
              imageUrl.startsWith('https://'))) {
        processedItem['cover_image'] =
            'https://wyrzhjomcvdokocanpjv.supabase.co/storage/v1/object/public/$imageUrl';
      }

      // Processar foto do autor se existir
      if (processedItem['authors'] != null &&
          processedItem['authors']['photo_url'] != null) {
        final authorPhotoUrl = processedItem['authors']['photo_url'].toString();
        if (authorPhotoUrl.isNotEmpty &&
            !(authorPhotoUrl.startsWith('http://') ||
                authorPhotoUrl.startsWith('https://'))) {
          processedItem['authors']['photo_url'] =
              'https://wyrzhjomcvdokocanpjv.supabase.co/storage/v1/object/public/$authorPhotoUrl';
        }
      }

      return processedItem;
    }).toList();
  }

  // Função para obter um livro específico
  Future<Map<String, dynamic>?> getBook(String id) async {
    try {
      // Primeiro tenta buscar da tabela 'livros'
      final response =
          await client.from('livros').select('*').eq('id', id).single();

      return response;
    } catch (e) {
      // Fallback para tabela 'books'
      final response =
          await client.from('books').select('*').eq('id', id).single();

      return response;
    }
  }

  // Função para salvar um livro novo
  Future<Map<String, dynamic>> createBook(Map<String, dynamic> bookData) async {
    try {
      String table = 'livros'; // Tabela padrão conforme imagem

      // Mapear campos para o formato correto
      Map<String, dynamic> mappedData = {};

      // Determinar qual tabela usar e mapear campos apropriadamente
      try {
        await client.from('livros').select('id').limit(1);
        table = 'livros';

        // Mapear para formato da tabela 'livros'
        mappedData = {
          'título': bookData['title'],
          'autor': bookData['author'],
          'descrição': bookData['descricao'],
          'imagem_de_capa': bookData['cover_image'] ?? bookData['thumbnail'],
          'páginas': bookData['pages'],
          'id_do_autor': bookData['author_id'],
          'id_da_categoria': bookData['category_id'],
          'criado_em': DateTime.now().toIso8601String(),
        };
      } catch (e) {
        table = 'books';

        // Mapear para formato da tabela 'books'
        mappedData = {
          'title': bookData['title'],
          'author': bookData['author'],
          'description': bookData['descricao'],
          'cover_image': bookData['cover_image'] ?? bookData['thumbnail'],
          'pages': bookData['pages'],
          'author_id': bookData['author_id'],
          'category_id': bookData['category_id'],
          'created_at': DateTime.now().toIso8601String(),
        };
      }

      // Salvar no Supabase
      final response =
          await client.from(table).insert(mappedData).select().single();

      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Função para atualizar um livro existente
  Future<Map<String, dynamic>> updateBook(
    String id,
    Map<String, dynamic> bookData,
  ) async {
    try {
      // Atualizar no Supabase
      final response =
          await client
              .from('books')
              .update(bookData)
              .eq('id', id)
              .select()
              .single();

      return {'success': true, 'data': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Funções para autores
  Future<List<Map<String, dynamic>>> getAuthors() async {
    try {
      // Primeiro tenta buscar da tabela 'autores' (conforme imagem)
      final response = await client.from('autores').select('*').order('nome');

      return response;
    } catch (e) {
      // Fallback para tabela 'authors'
      final response = await client.from('authors').select('*').order('name');

      return response;
    }
  }

  // Funções para categorias
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      // Primeiro tenta buscar da tabela 'categorias' (conforme imagem)
      final response = await client
          .from('categorias')
          .select('*')
          .order('nome');

      // Processar URLs das imagens
      return _processCategoryImageUrls(response, true);
    } catch (e) {
      // Fallback para tabela 'categories'
      final response = await client
          .from('categories')
          .select('*')
          .order('name');

      // Processar URLs das imagens
      return _processCategoryImageUrls(response, false);
    }
  }

  // Processa URLs de imagens das categorias
  List<Map<String, dynamic>> _processCategoryImageUrls(
    List<Map<String, dynamic>> data,
    bool isPortuguese,
  ) {
    return data.map((item) {
      // Clone o item para não modificar o original
      final processedItem = Map<String, dynamic>.from(item);

      // Campo de imagem dependendo da tabela
      final imageField = isPortuguese ? 'URL_da_imagem' : 'image_url';

      // Se o campo de imagem existir e não estiver vazio
      if (processedItem.containsKey(imageField) &&
          processedItem[imageField] != null &&
          processedItem[imageField].toString().isNotEmpty) {
        final imageUrl = processedItem[imageField].toString();

        // Se não for uma URL completa e for um caminho do storage
        if (!(imageUrl.startsWith('http://') ||
                imageUrl.startsWith('https://')) &&
            (imageUrl.startsWith('public/') || imageUrl.contains('storage/'))) {
          // Construir URL completa para o Supabase Storage
          final completeUrl =
              'https://wyrzhjomcvdokocanpjv.supabase.co/storage/v1/object/public/$imageUrl';
          processedItem[imageField] = completeUrl;
        }
      }

      return processedItem;
    }).toList();
  }

  // Função para obter o perfil do usuário
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response =
          await client.from('profiles').select('*').eq('id', userId).single();
      return response;
    } catch (e) {
      debugPrint('Erro ao buscar perfil do usuário: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getBookById(String bookId) async {
    try {
      final response =
          await client.from('books').select().eq('id', bookId).single();
      return response;
    } catch (e) {
      debugPrint('Erro ao buscar livro por ID: $e');
      return null;
    }
  }

  Future<AuthResponse> signInWithToken(String token) async {
    if (!_isInitialized) await initialize();

    try {
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: token,
      );
      debugPrint('SupabaseService: Login com token realizado com sucesso');
      return response;
    } catch (e) {
      debugPrint('SupabaseService: Erro no login com token: $e');
      rethrow;
    }
  }

  // Função para atualizar o progresso de leitura do usuário
  Future<bool> updateReadingProgress(
    String userId,
    String bookId,
    int pageIndex,
    int stepIndex,
  ) async {
    try {
      // Obter o progresso atual
      final userProfile = await getUserProfile(userId);
      if (userProfile == null) {
        debugPrint('Perfil não encontrado para atualizar progresso');
        return false;
      }

      // Obter o campo progress ou inicializar se não existir
      final progress =
          userProfile['progress'] != null
              ? Map<String, dynamic>.from(userProfile['progress'])
              : <String, dynamic>{};

      // Atualizar o progresso para o livro atual
      progress[bookId] = {'page': pageIndex, 'step': stepIndex};

      // Salvar no perfil do usuário
      await client
          .from('profiles')
          .update({'progress': progress})
          .eq('id', userId);

      debugPrint('Progresso de leitura atualizado com sucesso');
      return true;
    } catch (e) {
      debugPrint('Erro ao atualizar progresso de leitura: $e');
      return false;
    }
  }

  // Função para remover um livro do progresso (quando termina a leitura)
  Future<bool> removeBookFromProgress(String userId, String bookId) async {
    try {
      // Obter o progresso atual
      final userProfile = await getUserProfile(userId);
      if (userProfile == null) {
        debugPrint('Perfil não encontrado para remover progresso');
        return false;
      }

      // Se não tiver progresso, não fazer nada
      if (userProfile['progress'] == null) return true;

      // Converter para Map e remover o livro
      final progress = Map<String, dynamic>.from(userProfile['progress']);
      progress.remove(bookId);

      // Salvar no perfil do usuário
      await client
          .from('profiles')
          .update({'progress': progress})
          .eq('id', userId);

      debugPrint('Livro removido do progresso com sucesso');
      return true;
    } catch (e) {
      debugPrint('Erro ao remover livro do progresso: $e');
      return false;
    }
  }

  // Função para obter os livros em progresso do usuário
  Future<List<Map<String, dynamic>>> getBooksInProgress(String userId) async {
    try {
      // Obter o perfil do usuário
      final userProfile = await getUserProfile(userId);
      if (userProfile == null || userProfile['progress'] == null) {
        return [];
      }

      // Obter o progresso
      final progress = Map<String, dynamic>.from(userProfile['progress']);
      if (progress.isEmpty) return [];

      // Lista para armazenar os livros com seus dados completos
      final List<Map<String, dynamic>> booksInProgress = [];

      // Buscar os dados completos de cada livro
      for (final bookId in progress.keys) {
        final bookData = await getBookById(bookId);
        if (bookData != null) {
          // Adicionar informações de progresso ao livro
          final bookWithProgress = {
            ...bookData,
            'saved_page': progress[bookId]['page'],
            'saved_step': progress[bookId]['step'],
          };
          booksInProgress.add(bookWithProgress);
        }
      }

      // Processar URLs de imagens
      return _processImageUrls(booksInProgress, false);
    } catch (e) {
      debugPrint('Erro ao buscar livros em progresso: $e');
      return [];
    }
  }

  // Função para incrementar o contador de livros lidos (books_read)
  Future<bool> incrementBooksRead(String userId, {required int bookId}) async {
    try {
      final userProfile = await getUserProfile(userId);
      if (userProfile == null) {
        debugPrint('Perfil não encontrado para incrementar books_read');
        return false;
      }
      int currentBooksRead = 0;
      if (userProfile['books_read'] is int) {
        currentBooksRead = userProfile['books_read'] as int;
      } else if (userProfile['books_read'] is String) {
        currentBooksRead = int.tryParse(userProfile['books_read']) ?? 0;
      }
      final newBooksRead = currentBooksRead + 1;

      // Atualizar histórico de livros lidos
      List<dynamic> booksReadHistory = [];
      if (userProfile['books_read_history'] is List) {
        booksReadHistory = List.from(userProfile['books_read_history']);
      }
      if (!booksReadHistory.contains(bookId)) {
        booksReadHistory.add(bookId);
      }

      await client
          .from('profiles')
          .update({
            'books_read': newBooksRead,
            'books_read_history': booksReadHistory,
          })
          .eq('id', userId);
      debugPrint(
        'Contador de livros lidos incrementado para: $newBooksRead e histórico atualizado',
      );
      return true;
    } catch (e) {
      debugPrint('Erro ao incrementar contador de livros lidos: $e');
      return false;
    }
  }

  // Função para obter contador de livros em progresso
  Future<int> getInProgressBooksCount(String userId) async {
    try {
      // Obter o perfil do usuário
      final userProfile = await getUserProfile(userId);
      if (userProfile == null || userProfile['progress'] == null) {
        return 0;
      }

      // Obter o progresso
      final progress = Map<String, dynamic>.from(userProfile['progress']);

      // Retornar a quantidade de livros em progresso
      return progress.length;
    } catch (e) {
      debugPrint('Erro ao obter contador de livros em progresso: $e');
      return 0;
    }
  }
}
