import 'package:get/get.dart';
import '../../../core/services/luditeca_api_service.dart';
import '../../../core/controllers/auth_controller.dart';

class HomeController extends GetxController {
  static bool _routeObserverRegistered = false;

  final LuditecaApiService _apiService = LuditecaApiService();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<Map<String, dynamic>> _books = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _booksInProgress =
      <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isLoadingProgress = false.obs;
  final RxString _error = ''.obs;
  bool _progressInflight = false;

  // Variável para rastrear a rota atual
  final RxString _currentRoute = ''.obs;

  List<Map<String, dynamic>> get books => _books;
  List<Map<String, dynamic>> get booksInProgress => _booksInProgress;
  bool get isLoading => _isLoading.value;
  bool get isLoadingProgress => _isLoadingProgress.value;
  String? get error => _error.value.isEmpty ? null : _error.value;

  @override
  void onInit() {
    super.onInit();
    _loadData();

    // Adicionar listener para atualizar quando a rota mudar para home
    ever(_currentRoute, (route) {
      if (route == '/home') {
        _loadData();
      }
    });

    // Observar mudanças de rota
    _setupRouteObserver();
  }

  void _setupRouteObserver() {
    if (_routeObserverRegistered) return;
    _routeObserverRegistered = true;

    Get.put(
      GetObserver((Routing? routing) {
        if (routing?.current != null) {
          _currentRoute.value = routing!.current;
        }
      }),
      permanent: true,
    );
  }

  // Método para carregar todos os dados. O catálogo vem da cache em memória
  // da API (só [forceRefresh] vai à rede); o progresso é sempre relido.
  Future<void> _loadData({bool forceRefresh = false}) async {
    await Future.wait([
      loadBooks(forceRefresh: forceRefresh),
      if (_authController.isAuthenticated) loadBooksInProgress(),
    ]);
  }

  // Pull-to-refresh: força nova leitura do catálogo.
  Future<void> refreshData({bool forceRefresh = true}) async {
    await _loadData(forceRefresh: forceRefresh);
  }

  /// Regresso ao ecrã / app retomada: reaproveita a cache do catálogo.
  Future<void> reloadOnReturn() => _loadData();

  Future<void> loadBooks({bool forceRefresh = false}) async {
    // Só mostra o indicador quando ainda não há nada para mostrar.
    if (_books.isEmpty) _setLoading(true);
    try {
      final books = await _apiService.getBooks(forceRefresh: forceRefresh);

      // Ordenar por ID em ordem decrescente
      books.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
      _books.value = books;
    } catch (e) {
      _setError('Erro ao carregar livros: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadBooksInProgress() async {
    if (!_authController.isAuthenticated) return;
    // Evita pedidos sobrepostos (rota + lifecycle + regresso do leitor).
    if (_progressInflight) return;
    _progressInflight = true;

    if (_booksInProgress.isEmpty) _isLoadingProgress.value = true;
    try {
      final userId = _authController.currentUser!['id'].toString();
      final booksInProgress = await _apiService.getBooksInProgress(userId);
      _booksInProgress.value = booksInProgress;
    } catch (e) {
      _setError('Erro ao carregar livros em progresso: $e');
    } finally {
      _isLoadingProgress.value = false;
      _progressInflight = false;
    }
  }

  void _setLoading(bool value) {
    _isLoading.value = value;
  }

  void _setError(String? value) {
    _error.value = value ?? '';
  }

  @override
  void onClose() {
    _books.clear();
    _booksInProgress.clear();
    super.onClose();
  }
}
