import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService();

  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final Rx<User?> _currentUser = Rx<User?>(null);
  final RxBool _initialLoadCompleted = false.obs;

  bool get isLoading => _isLoading.value;
  String? get error => _error.value.isEmpty ? null : _error.value;
  User? get currentUser => _currentUser.value;
  bool get isAuthenticated => _currentUser.value != null;
  bool get initialLoadCompleted => _initialLoadCompleted.value;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUser();
    _setupAuthListener();
  }

  void _loadCurrentUser() {
    debugPrint('AuthController: Carregando usuário atual');
    _currentUser.value = _supabaseService.getCurrentUser();
    if (_currentUser.value != null) {
      debugPrint(
        'AuthController: Usuário já logado: ${_currentUser.value!.email}',
      );
    } else {
      debugPrint('AuthController: Nenhum usuário logado');
    }
    _initialLoadCompleted.value = true;
  }

  void _setupAuthListener() {
    debugPrint('AuthController: Configurando listener de autenticação');
    _supabaseService.authStateChanges().listen((state) {
      debugPrint('AuthController: Evento de autenticação: ${state.event}');

      if (state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.userUpdated) {
        _currentUser.value = state.session?.user;
        debugPrint(
          'AuthController: Usuário logado: ${_currentUser.value?.email}',
        );
      } else if (state.event == AuthChangeEvent.signedOut) {
        _currentUser.value = null;
        debugPrint('AuthController: Usuário deslogado');
      }
    });
  }

  Future<bool> signIn(String email, String password) async {
    _error.value = '';
    _isLoading.value = true;

    debugPrint('AuthController: Tentando login com email: $email');

    try {
      final response = await _supabaseService.signIn(email, password);
      _currentUser.value = response.user;
      _isLoading.value = false;

      debugPrint(
        'AuthController: Login bem sucedido para: ${_currentUser.value?.email}',
      );

      return true;
    } on AuthException catch (e) {
      _error.value = _getAuthErrorMessage(e);
      _isLoading.value = false;
      debugPrint('AuthController: Erro no login: ${_error.value}');
      return false;
    } catch (e) {
      _error.value = 'Erro inesperado: $e';
      _isLoading.value = false;
      debugPrint('AuthController: Erro inesperado no login: ${_error.value}');
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    _error.value = '';
    _isLoading.value = true;

    try {
      final response = await _supabaseService.signUp(email, password);
      _currentUser.value = response.user;
      _isLoading.value = false;
      return response.session != null;
    } on AuthException catch (e) {
      _error.value = _getAuthErrorMessage(e);
      _isLoading.value = false;
      debugPrint('AuthController: Erro no registro: ${_error.value}');
      return false;
    } catch (e) {
      _error.value = 'Erro inesperado: $e';
      _isLoading.value = false;
      debugPrint(
        'AuthController: Erro inesperado no registro: ${_error.value}',
      );
      return false;
    }
  }

  Future<bool> signOut() async {
    _error.value = '';
    _isLoading.value = true;

    try {
      await _supabaseService.signOut();
      _currentUser.value = null;
      _isLoading.value = false;
      return true;
    } catch (e) {
      _error.value = 'Erro ao fazer logout: $e';
      _isLoading.value = false;
      debugPrint('AuthController: Erro no logout: ${_error.value}');
      return false;
    }
  }

  Future<bool> signInWithQRCode(String qrCodeData) async {
    _error.value = '';
    _isLoading.value = true;

    debugPrint('AuthController: Tentando login com QR Code');

    try {
      // Decodificar o QR code (assumindo que contém um token JWT)
      final token = _decodeQRCode(qrCodeData);
      if (token == null) {
        throw AuthException('QR Code inválido');
      }

      // Autenticar com o token
      final response = await _supabaseService.signInWithToken(token);
      _currentUser.value = response.user;
      _isLoading.value = false;

      debugPrint(
        'AuthController: Login com QR Code bem sucedido para: ${_currentUser.value?.email}',
      );

      return true;
    } on AuthException catch (e) {
      _error.value = _getAuthErrorMessage(e);
      _isLoading.value = false;
      debugPrint('AuthController: Erro no login com QR Code: ${_error.value}');
      return false;
    } catch (e) {
      _error.value = 'Erro ao processar QR Code: $e';
      _isLoading.value = false;
      debugPrint(
        'AuthController: Erro inesperado no login com QR Code: ${_error.value}',
      );
      return false;
    }
  }

  String? _decodeQRCode(String qrCodeData) {
    try {
      // Aqui você implementaria a lógica real para decodificar o QR code
      // Por exemplo, usando um pacote como qr_code_scanner ou mobile_scanner
      // e extraindo o token JWT do conteúdo

      // Por enquanto, vamos assumir que o QR code contém diretamente o token
      if (qrCodeData.startsWith('eyJ')) {
        // Verifica se parece um JWT
        return qrCodeData;
      }
      return null;
    } catch (e) {
      debugPrint('AuthController: Erro ao decodificar QR Code: $e');
      return null;
    }
  }

  String _getAuthErrorMessage(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Email ou senha inválidos';
      case 'Email not confirmed':
        return 'Email não confirmado';
      case 'User already registered':
        return 'Usuário já registrado';
      case 'Password should be at least 6 characters':
        return 'A senha deve ter pelo menos 6 caracteres';
      case 'Invalid email':
        return 'Email inválido';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }

  void clearError() {
    _error.value = '';
  }
}
