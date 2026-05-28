import 'package:get/get.dart';
import '../core/preferences/app_preferences_controller.dart';
import '../modules/activities/pages/activities_placeholder_page.dart';
import '../modules/favorites/pages/favorites_page.dart';
import '../modules/favorites/controllers/favorites_controller.dart';
import '../modules/profile/pages/profile_page.dart';
import '../modules/profile/controllers/profile_controller.dart';
import '../modules/settings/pages/settings_page.dart';

class AppPages {
  static void initControllers() {
    Get.put(AppPreferencesController(), permanent: true);
    Get.lazyPut(() => FavoritesController(), fenix: true);
    Get.lazyPut(() => ProfileController(), fenix: true);
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
        Get.lazyPut(() => ProfileController(), fenix: true);
      }),
    ),
    GetPage(name: '/activities', page: () => const ActivitiesPlaceholderPage()),
    GetPage(name: '/settings', page: () => const SettingsPage()),
  ];
}
