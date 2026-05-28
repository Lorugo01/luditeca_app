import 'package:get/get.dart';

/// Navegação entre abas principais sem reanimar a aba já activa.
abstract final class AppShellNavigator {
  /// Rota actual normalizada (`/` → `/home`).
  static String get currentRoute {
    final raw = Get.currentRoute;
    if (raw == '/' || raw.isEmpty) return '/home';
    return raw;
  }

  static bool isTabActive(List<String> activeRoots) {
    final current = currentRoute;
    return activeRoots.any(
      (root) => current == root || current.startsWith('$root/'),
    );
  }

  /// Vai para uma aba principal. Ignora se já estiver na mesma rota.
  static void goToTab({
    required String route,
    required List<String> activeRoots,
  }) {
    final current = currentRoute;
    final onTab = isTabActive(activeRoots);

    if (onTab && current == route) {
      return;
    }

    if (onTab && current != route) {
      // Ex.: em `/category-books` → voltar a `/library`.
      Get.offNamed(route);
      return;
    }

    Get.offNamed(route);
  }

  /// Atalhos da home e barra lateral.
  static void goToHome() => goToTab(route: '/home', activeRoots: const ['/home']);
  static void goToLibrary() =>
      goToTab(route: '/library', activeRoots: const ['/library', '/category-books']);
  static void goToFavorites() =>
      goToTab(route: '/favorites', activeRoots: const ['/favorites']);
  static void goToActivities() =>
      goToTab(route: '/activities', activeRoots: const ['/activities']);
  static void goToSettings() =>
      goToTab(route: '/settings', activeRoots: const ['/settings', '/profile']);
}
