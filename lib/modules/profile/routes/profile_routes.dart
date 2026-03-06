import 'package:get/get.dart';
import '../pages/profile_page.dart';

class ProfileRoutes {
  static final routes = [
    GetPage(name: '/profile', page: () => const ProfilePage()),
  ];
}
