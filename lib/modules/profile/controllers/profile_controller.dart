import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/services/luditeca_api_service.dart';
import '../../../core/utils/app_messenger.dart';
import '../data/profile_age_band.dart';
import '../data/profile_avatars.dart';
import '../data/profile_achievements.dart';
import '../data/profile_xp_level.dart';

class ProfileController extends GetxController {
  final LuditecaApiService _service = LuditecaApiService();
  final RxMap<String, dynamic> userProfile = RxMap<String, dynamic>();
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString userName = ''.obs;
  final RxString icone = ''.obs;
  final RxString avatarId = 'girl1'.obs;
  final RxInt userAge = 10.obs;
  final RxInt xpTotal = 0.obs;
  final RxInt xpBalance = 0.obs;

  final RxInt booksRead = 0.obs;
  final RxString role = 'aluno'.obs;
  final RxInt favorites = 0.obs;
  final RxMap<String, dynamic> progress = RxMap<String, dynamic>();
  final RxInt booksInProgress = 0.obs;
  final RxMap<String, dynamic> permissions = RxMap<String, dynamic>();
  final RxList<int> booksReadHistory = <int>[].obs;
  final RxList<String> unlockedBadges = <String>[].obs;
  final RxList<AchievementProgress> achievements = <AchievementProgress>[].obs;
  final RxBool achievementsLoading = false.obs;
  final RxInt pagesRead = 0.obs;
  final RxInt readingHours = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;
      error.value = '';

      final userId = _service.currentUser?['id']?.toString();
      if (userId == null) {
        error.value = 'Usuário não autenticado';
        return;
      }
      final response = await _service.getUserProfile(userId) ?? {};

      userProfile.assignAll(response);

      userName.value = (response['name']?.toString().trim().isNotEmpty == true)
          ? response['name'].toString()
          : (_service.currentUser?['name']?.toString() ?? 'Usuário');
      icone.value = response['icone']?.toString() ?? '';

      final dbAvatarId = response['avatar_id']?.toString();
      avatarId.value = (dbAvatarId != null && dbAvatarId.isNotEmpty)
          ? dbAvatarId
          : (profileAvatarIdFromUrl(icone.value) ?? 'girl1');

      final dbAge = _asInt(response['age'], 0);
      userAge.value = dbAge > 0 ? dbAge : 10;

      role.value = response['role']?.toString() ?? 'aluno';
      permissions.assignAll(response['permissions'] ?? {});

      booksReadHistory.value =
          (response['books_read_history'] as List<dynamic>? ?? [])
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e != 0)
              .toList();

      var readCount = _asInt(response['books_read']);
      if (readCount == 0 && booksReadHistory.isNotEmpty) {
        readCount = booksReadHistory.length;
      }
      booksRead.value = readCount;

      var xp = _asInt(response['xp_total']);
      var xpAvail = _asInt(response['xp_balance']);
      xpTotal.value = xp;
      xpBalance.value = xpAvail;

      progress.assignAll(response['progress'] ?? {});
      booksInProgress.value = _countBooksInProgress(progress);

      final favoriteIds = response['favorites'];
      if (favoriteIds is List && favoriteIds.isNotEmpty) {
        favorites.value = favoriteIds.length;
      } else {
        try {
          final books = await _service.getFavoriteBooks();
          favorites.value = books.length;
        } catch (_) {
          favorites.value = 0;
        }
      }

      final stats = response['stats'];
      if (stats is Map) {
        pagesRead.value = _asInt(stats['pages_read']);
        readingHours.value = _asInt(stats['reading_hours']);
      }

      final badgeList = response['badges'];
      if (badgeList is List) {
        unlockedBadges.value =
            badgeList.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }

      debugPrint(
        'Perfil: idade=${userAge.value} xp=$xp livros=$readCount',
      );

      await loadAchievements();
    } catch (e) {
      error.value = 'Erro ao carregar perfil: $e';
      debugPrint('Erro ao carregar perfil: $e');
    } finally {
      isLoading.value = false;
    }
  }

  int _countBooksInProgress(Map<String, dynamic> progressMap) {
    var count = 0;
    for (final entry in progressMap.entries) {
      final key = entry.key.toString();
      if (key == '__xp_meta' || key.startsWith('__')) continue;
      final raw = entry.value;
      if (raw is! Map) continue;
      final page = _asInt(raw['page']);
      final step = _asInt(raw['step']);
      if (page > 0 || step > 0) count++;
    }
    return count;
  }

  String get displayAvatarUrl {
    if (icone.value.isNotEmpty) return icone.value;
    return findProfileAvatar(avatarId.value)?.pngUrl ?? kProfileAvatars.first.pngUrl;
  }

  String get userEmail => _service.currentUser?['email']?.toString() ?? '';

  String get avatarCharacterLabel {
    final preset = findProfileAvatar(avatarId.value);
    if (preset != null) return preset.label;
    if (icone.value.isNotEmpty) return 'Foto personalizada';
    return kProfileAvatars.first.label;
  }

  ProfileAgeBand get ageBand => ProfileAgeBand.forAge(userAge.value);

  String get roleLabel {
    switch (role.value.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'editor':
        return 'Editor';
      case 'professor':
        return 'Professor';
      case 'aluno':
      default:
        return 'Aluno';
    }
  }

  /// Nível e progresso calculados a partir do [xpTotal] (não dos livros lidos).
  ProfileLevelSnapshot get xpLevel => ProfileXpLevel.snapshot(xpTotal.value);

  int get unlockedAchievementsCount =>
      achievements.where((a) => a.unlocked && !a.def.comingSoon).length;

  Future<void> loadAchievements() async {
    if (!_service.isAuthenticated) return;
    try {
      achievementsLoading.value = true;
      final data = await _service.getAchievements();
      if (data == null) return;

      xpTotal.value = _asInt(data['xp_total'], xpTotal.value);
      xpBalance.value = _asInt(data['xp_balance'], xpBalance.value);

      final stats = data['stats'];
      if (stats is Map) {
        pagesRead.value = _asInt(stats['pages_read']);
        readingHours.value = _asInt(stats['reading_hours']);
        booksRead.value = _asInt(stats['books_read'], booksRead.value);
      }

      final badgeList = data['badges'];
      if (badgeList is List) {
        unlockedBadges.value =
            badgeList.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }

      final list = data['achievements'];
      if (list is List) {
        achievements.value = list
            .whereType<Map>()
            .map((e) => AchievementProgress.fromApi(
                  Map<String, dynamic>.from(e),
                ))
            .toList();
      }
    } catch (e) {
      debugPrint('Erro ao carregar conquistas: $e');
      if (achievements.isEmpty) {
        achievements.value = kProfileAchievements
            .map(
              (def) => AchievementProgress(
                def: def,
                current: 0,
                unlocked: unlockedBadges.contains(def.id),
              ),
            )
            .toList();
      }
    } finally {
      achievementsLoading.value = false;
    }
  }

  /// Actualiza XP/conquistas após leitura ou PATCH de perfil.
  void applyGamificationResult(Map<String, dynamic>? result) {
    if (result == null) return;

    if (result['xp_total'] != null) {
      xpTotal.value = _asInt(result['xp_total'], xpTotal.value);
    }
    if (result['xp_balance'] != null) {
      xpBalance.value = _asInt(result['xp_balance'], xpBalance.value);
    }

    final stats = result['stats'];
    if (stats is Map) {
      pagesRead.value = _asInt(stats['pages_read'], pagesRead.value);
      readingHours.value = _asInt(stats['reading_hours'], readingHours.value);
    }

    final unlocked = result['achievements_unlocked'] ?? result['newly_unlocked'];
    if (unlocked is List && unlocked.isNotEmpty) {
      for (final raw in unlocked) {
        if (raw is! Map) continue;
        final title = raw['title']?.toString() ?? 'Conquista';
        final xp = _asInt(raw['xp_reward']);
        AppMessenger.success('$title (+$xp XP)', title: '🏆 Conquista');
      }
      loadAchievements();
    } else if (result['achievements'] is List) {
      final list = result['achievements'] as List;
      achievements.value = list
          .whereType<Map>()
          .map((e) => AchievementProgress.fromApi(Map<String, dynamic>.from(e)))
          .toList();
    }
  }

  /// Salva perfil no banco (API VPS).
  Future<bool> updateProfile({
    required String name,
    String? iconeUrl,
    int? age,
    String? selectedAvatarId,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final userId = _service.currentUser?['id']?.toString();
      if (userId == null) {
        error.value = 'Usuário não autenticado';
        return false;
      }

      String? url = iconeUrl;
      if (selectedAvatarId != null) {
        final preset = findProfileAvatar(selectedAvatarId);
        if (preset != null) url = preset.pngUrl;
      }

      final updated = await _service.updateMyProfile(
        name: name,
        iconeUrl: url,
        age: age,
        avatarId: selectedAvatarId ?? avatarId.value,
      );

      userName.value = updated['name']?.toString() ?? name;
      if (url != null) icone.value = url;
      if (age != null) userAge.value = age;
      if (selectedAvatarId != null) avatarId.value = selectedAvatarId;

      xpTotal.value = _asInt(updated['xp_total'], xpTotal.value);
      xpBalance.value = _asInt(updated['xp_balance'], xpBalance.value);

      return true;
    } catch (e) {
      error.value = 'Erro ao atualizar perfil: $e';
      AppMessenger.error('Não foi possível atualizar o perfil: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Abre seletor e envia foto. Retorna `true` se a foto foi gravada no servidor.
  Future<bool> pickAndUploadProfileImage(BuildContext context) async {
    if (Platform.isWindows && !kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result == null || result.files.single.path == null) return false;
      return uploadProfileImageWindows(result.files.single.path!);
    }

    if (!context.mounted) return false;
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selecionar imagem'),
        content: const Text(
          'Escolha de onde deseja obter a imagem de perfil:',
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.photo),
            label: const Text('Galeria'),
            onPressed: () => Navigator.of(ctx).pop(ImageSource.gallery),
          ),
          TextButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('Câmera'),
            onPressed: () => Navigator.of(ctx).pop(ImageSource.camera),
          ),
        ],
      ),
    );
    if (source == null) return false;
    return uploadProfileImage(source);
  }

  Future<bool> uploadProfileImageWindows(String filePath) async {
    try {
      error.value = '';
      final userId = _service.currentUser?['id']?.toString();
      if (userId == null) {
        error.value = 'Usuário não autenticado';
        return false;
      }
      final fileName = 'profile_$userId.jpg';
      final bytes = await File(filePath).readAsBytes();
      final publicUrl = await _service.uploadAvatar(
        bytes: bytes,
        fileName: fileName,
      );
      return _persistPhotoUrl(publicUrl);
    } catch (e) {
      error.value = 'Erro ao atualizar foto: $e';
      AppMessenger.error('Não foi possível atualizar a foto: $e');
      return false;
    }
  }

  Future<bool> uploadProfileImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 85,
      );
      if (image == null) return false;

      error.value = '';
      final userId = _service.currentUser?['id']?.toString();
      if (userId == null) {
        error.value = 'Usuário não autenticado';
        return false;
      }

      final fileName = 'profile_$userId.jpg';
      final bytes = await File(image.path).readAsBytes();
      final publicUrl = await _service.uploadAvatar(
        bytes: bytes,
        fileName: fileName,
      );
      return _persistPhotoUrl(publicUrl);
    } catch (e) {
      error.value = 'Erro ao atualizar foto: $e';
      AppMessenger.error('Não foi possível atualizar a foto: $e');
      return false;
    }
  }

  Future<bool> _persistPhotoUrl(String publicUrl) async {
    final updated = await _service.updateMyProfile(
      name: userName.value,
      iconeUrl: publicUrl,
      age: userAge.value,
      avatarId: avatarId.value,
    );
    icone.value = publicUrl;
    userName.value = updated['name']?.toString() ?? userName.value;
    xpTotal.value = _asInt(updated['xp_total'], xpTotal.value);
    xpBalance.value = _asInt(updated['xp_balance'], xpBalance.value);
    return true;
  }

  Future<void> signOut() async {
    try {
      await _service.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      error.value = 'Erro ao fazer logout: $e';
      AppMessenger.error('Não foi possível fazer logout: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchBooksReadHistory() async {
    if (booksReadHistory.isEmpty) return [];
    return _service.fetchBooksByIds(booksReadHistory);
  }
}
