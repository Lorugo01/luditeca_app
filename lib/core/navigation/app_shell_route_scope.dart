import 'package:get/get.dart';

import 'app_shell_navigator.dart';

/// Sincroniza a rota actual com a barra lateral / inferior (GetX não rebuilda sozinho).
class AppShellRouteScope extends GetxController {
  final RxString route = '/home'.obs;

  @override
  void onInit() {
    super.onInit();
    sync();
  }

  void sync() {
    route.value = AppShellNavigator.currentRoute;
  }
}
