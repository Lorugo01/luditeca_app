import 'package:get/get.dart';
import '../core/controllers/orientation_controller.dart';
import '../core/navigation/app_shell_route_scope.dart';
import '../core/preferences/app_preferences_controller.dart';
import '../modules/activities/pages/activities_placeholder_page.dart';
import '../modules/favorites/pages/favorites_page.dart';
import '../modules/favorites/controllers/favorites_controller.dart';
import '../modules/profile/pages/achievements_page.dart';
import '../modules/profile/pages/profile_edit_page.dart';
import '../modules/profile/pages/profile_page.dart';
import '../modules/profile/controllers/profile_controller.dart';
import '../modules/settings/pages/settings_offline_page.dart';
import '../modules/settings/pages/settings_page.dart';
import '../modules/settings/pages/theme_picker_page.dart';

class AppPages {
  static void initControllers() {
    Get.put(AppPreferencesController(), permanent: true);
    Get.put(AppShellRouteScope(), permanent: true);
    Get.put(OrientationController(), permanent: true);
    Get.lazyPut(() => FavoritesController(), fenix: true);
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController(), permanent: true);
    }
  }

  static final routes = [
    GetPage(
      name: '/favorites',
      page: () => const FavoritesPage(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => FavoritesController(), fenix: true);
      }),
    ),
    GetPage(
      name: '/profile',
      page: () => const ProfilePage(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController(), permanent: true);
        }
      }),
    ),
    // /profile/edit — só grelha de avatares + nome/idade (abrir a partir de Meu Perfil)
    GetPage(
      name: '/profile/edit',
      page: () => const ProfileEditPage(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController(), permanent: true);
        }
      }),
    ),
    GetPage(
      name: '/achievements',
      page: () => const AchievementsPage(),
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<ProfileController>()) {
          Get.put(ProfileController(), permanent: true);
        }
      }),
    ),
    GetPage(name: '/activities', page: () => const ActivitiesPlaceholderPage()),
    GetPage(name: '/settings', page: () => const SettingsPage()),
    GetPage(name: '/settings/themes', page: () => const ThemePickerPage()),
    GetPage(name: '/settings/offline', page: () => const SettingsOfflinePage()),
  ];
}
