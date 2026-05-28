import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/luditeca_api_service.dart';

class AuthController extends GetxController {
  final LuditecaApiService _apiService = LuditecaApiService();

  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final Rx<Map<String, dynamic>?> _currentUser = Rx<Map<String, dynamic>?>(null);
  final RxBool _initialLoadCompleted = false.obs;

  bool get isLoading => _isLoading.value;
  String? get error => _error.value.isEmpty ? null : _error.value;
  Map<String, dynamic>? get currentUser => _currentUser.value;
  bool get isAuthenticated => _currentUser.value != null;
  bool get initialLoadCompleted => _initialLoadCompleted.value;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    _currentUser.value = _apiService.getCurrentUser();
    _initialLoadCompleted.value = true;
  }

  Future<bool> signIn(String email, String password) async {
    _error.value = '';
    _isLoading.value = true;

    try {
      final response = await _apiService.signIn(email, password);
      _currentUser.value = Map<String, dynamic>.from(response['user'] as Map);
      _isLoading.value = false;

      return true;
    } catch (e) {
      _error.value = 'Erro inesperado: $e';
      _isLoading.value = false;
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    _error.value = '';
    _isLoading.value = true;

    try {
      final response = await _apiService.signUp(email, password);
      _currentUser.value = Map<String, dynamic>.from(response['user'] as Map);
      _isLoading.value = false;
      return response['session'] != null;
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
      await _apiService.signOut();
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
        throw Exception('QR Code inválido');
      }

      // Autenticar com o token
      final response = await _apiService.signInWithToken(token);
      _currentUser.value = Map<String, dynamic>.from(response['user'] as Map);
      _isLoading.value = false;

      debugPrint(
        'AuthController: Login com QR Code bem sucedido para: ${_currentUser.value?['email']}',
      );

      return true;
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

  void clearError() {
    _error.value = '';
  }
}
