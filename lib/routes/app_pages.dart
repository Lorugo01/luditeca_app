import 'package:get/get.dart';
import '../modules/favorites/pages/favorites_page.dart';
import '../modules/favorites/controllers/favorites_controller.dart';
import '../modules/profile/pages/profile_page.dart';
import '../modules/profile/controllers/profile_controller.dart';

class AppPages {
  static void initControllers() {
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
  ];
}
