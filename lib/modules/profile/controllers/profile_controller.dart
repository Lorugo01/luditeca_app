import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileController extends GetxController {
  final supabase = Supabase.instance.client;
  final RxMap<String, dynamic> userProfile = RxMap<String, dynamic>();
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString userName = ''.obs;
  final RxString icone = ''.obs;

  // Campos específicos do perfil
  final RxInt booksRead = 0.obs;
  final RxString role = 'aluno'.obs;
  final RxInt favorites = 0.obs;
  final RxMap<String, dynamic> progress = RxMap<String, dynamic>();
  final RxInt booksInProgress = 0.obs;
  final RxMap<String, dynamic> permissions = RxMap<String, dynamic>();
  final RxList<int> booksReadHistory = <int>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;
      error.value = '';

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        error.value = 'Usuário não autenticado';
        return;
      }

      final response =
          await supabase.from('profiles').select('*').eq('id', userId).single();

      userProfile.assignAll(response);

      // Atualiza os campos específicos
      userName.value = response['name'] ?? 'Usuário';
      icone.value = response['icone'] ?? '';
      booksRead.value = response['books_read'] ?? 0;
      role.value = response['role'] ?? 'aluno';
      favorites.value = response['favorites']?.length ?? 0;
      progress.assignAll(response['progress'] ?? {});
      booksInProgress.value = (response['progress'] as Map?)?.length ?? 0;
      permissions.assignAll(response['permissions'] ?? {});
      // Buscar histórico de livros lidos
      booksReadHistory.value =
          (response['books_read_history'] as List<dynamic>? ?? [])
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e != 0)
              .toList();

      debugPrint('Perfil carregado: $response');
    } catch (e) {
      error.value = 'Erro ao carregar perfil: $e';
      debugPrint('Erro ao carregar perfil: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile({required String name, String? iconeUrl}) async {
    try {
      isLoading.value = true;
      error.value = '';

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        error.value = 'Usuário não autenticado';
        return;
      }

      final updates = {'name': name, if (iconeUrl != null) 'icone': iconeUrl};

      await supabase.from('profiles').update(updates).eq('id', userId);

      await loadUserProfile();

      Get.snackbar(
        'Sucesso',
        'Perfil atualizado com sucesso',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      error.value = 'Erro ao atualizar perfil: $e';
      Get.snackbar(
        'Erro',
        'Não foi possível atualizar o perfil: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickAndUploadProfileImage(BuildContext context) async {
    if (Platform.isWindows && !kIsWeb) {
      // Windows Desktop: usar file_picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        await uploadProfileImageWindows(result.files.single.path!);
      }
      return;
    }
    // Mobile/Web: usar image_picker
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Selecionar imagem'),
            content: const Text(
              'Escolha de onde deseja obter a imagem de perfil:',
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.photo),
                label: const Text('Galeria'),
                onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              TextButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Câmera'),
                onPressed: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
    );
    if (source != null) {
      await uploadProfileImage(source);
    }
  }

  Future<void> uploadProfileImageWindows(String filePath) async {
    try {
      isLoading.value = true;
      error.value = '';
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        error.value = 'Usuário não autenticado';
        return;
      }
      final String fileName = 'profile_$userId.jpg';
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      await supabase.storage
          .from('profile')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      final String publicUrl = supabase.storage
          .from('profile')
          .getPublicUrl(fileName);
      await updateProfile(name: userName.value, iconeUrl: publicUrl);
      Get.snackbar(
        'Sucesso',
        'Foto de perfil atualizada com sucesso',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      error.value = 'Erro ao atualizar foto: $e';
      Get.snackbar(
        'Erro',
        'Não foi possível atualizar a foto: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadProfileImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 85,
      );

      if (image == null) return;

      isLoading.value = true;
      error.value = '';

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        error.value = 'Usuário não autenticado';
        return;
      }

      // Upload da imagem para o storage do Supabase (bucket 'profile')
      final String fileName = 'profile_$userId.jpg';
      final file = File(image.path);
      final bytes = await file.readAsBytes();

      await supabase.storage
          .from('profile')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Obtém a URL pública da imagem
      final String publicUrl = supabase.storage
          .from('profile')
          .getPublicUrl(fileName);

      // Atualiza o perfil com a nova URL na coluna 'icone'
      await updateProfile(name: userName.value, iconeUrl: publicUrl);

      Get.snackbar(
        'Sucesso',
        'Foto de perfil atualizada com sucesso',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      error.value = 'Erro ao atualizar foto: $e';
      Get.snackbar(
        'Erro',
        'Não foi possível atualizar a foto: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      error.value = 'Erro ao fazer logout: $e';
      Get.snackbar(
        'Erro',
        'Não foi possível fazer logout: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchBooksReadHistory() async {
    if (booksReadHistory.isEmpty) return [];
    final response = await supabase
        .from('books')
        .select('*')
        .inFilter('id', booksReadHistory);
    return List<Map<String, dynamic>>.from(response);
  }
}
