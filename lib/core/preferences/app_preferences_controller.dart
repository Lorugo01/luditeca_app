import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';
import '../theme/app_theme_palette.dart';
import 'layout_option.dart';

/// Preferências de layout e tema (persistidas localmente).
class AppPreferencesController extends GetxController {
  static const _keyMenu = 'pref_menu_layout';
  static const _keyActivities = 'pref_activities_layout';
  static const _keyLibrary = 'pref_library_layout';
  static const _keyTheme = 'pref_app_theme';

  final RxString menuLayoutId = 'grid'.obs;
  final RxString activitiesLayoutId = 'grid'.obs;
  final RxString libraryLayoutId = 'shelf'.obs;
  final RxString appThemeId = AppThemeRegistry.defaultId.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    menuLayoutId.value = prefs.getString(_keyMenu) ?? 'grid';
    activitiesLayoutId.value = prefs.getString(_keyActivities) ?? 'grid';
    libraryLayoutId.value = prefs.getString(_keyLibrary) ?? 'shelf';

    final storedTheme = AppThemeRegistry.normalizeId(
      prefs.getString(_keyTheme) ?? AppThemeRegistry.defaultId,
    );
    appThemeId.value = storedTheme;
    AppThemeRegistry.setCurrent(storedTheme);
    Get.changeTheme(AppTheme.forId(storedTheme));
    Get.forceAppUpdate();
  }

  Future<void> setMenuLayout(String id) async {
    menuLayoutId.value = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMenu, id);
  }

  Future<void> setActivitiesLayout(String id) async {
    activitiesLayoutId.value = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActivities, id);
  }

  Future<void> setLibraryLayout(String id) async {
    libraryLayoutId.value = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLibrary, id);
  }

  Future<void> setAppTheme(String id) async {
    final normalized = AppThemeRegistry.normalizeId(id);
    appThemeId.value = normalized;
    AppThemeRegistry.setCurrent(normalized);
    Get.changeTheme(AppTheme.forId(normalized));
    // Reconstrói toda a árvore para que os tokens (cores) atualizem,
    // sem destruir o Navigator/Overlay (evita "No Overlay widget found").
    Get.forceAppUpdate();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, normalized);
  }

  String get menuLayoutLabel =>
      findLayoutOption(kMenuLayoutOptions, menuLayoutId.value)?.pickerLabel ??
      '⊞ Grade 2×2';

  String get activitiesLayoutLabel =>
      findLayoutOption(kActivitiesLayoutOptions, activitiesLayoutId.value)
          ?.pickerLabel ??
      '⊞ Grade 2×2';

  String get libraryLayoutLabel =>
      findLayoutOption(kLibraryLayoutOptions, libraryLayoutId.value)?.pickerLabel ??
      '📚 Prateleira 3D';

  /// Apaga chaves locais de progresso/leitura (não remove conta no servidor).
  Future<void> clearLocalAppData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) {
      return k.startsWith('reading_progress') ||
          k.startsWith('book_progress') ||
          k.startsWith('interactive_') ||
          k.startsWith('reader_');
    });
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
