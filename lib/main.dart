import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'core/services/luditeca_api_service.dart';
import 'core/config/app_env.dart';
import 'core/config/dev_api_resolver.dart';
import 'core/theme.dart';
import 'core/controllers/auth_controller.dart';
import 'core/pages/login_page.dart';
import 'modules/home/pages/home_page.dart';
import 'modules/library/pages/library_page.dart';
import 'modules/library/pages/category_books_page.dart';
import 'modules/library/controllers/library_controller.dart';
import 'core/preferences/app_preferences_controller.dart';
import 'core/navigation/app_shell_route_scope.dart';
import 'routes/app_pages.dart';

Future<void> _logApiReachability() async {
  final url = '${DevApiResolver.apiBaseUrl}/health';
  try {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
        validateStatus: (_) => true,
      ),
    );
    final res = await dio.get<dynamic>(url);
    debugPrint('API health: $url -> ${res.statusCode}');
  } catch (e) {
    debugPrint(
      'API inacessivel em $url. No emulador execute: '
      'adb reverse tcp:3020 tcp:3020 (ou use config "Tablet / IP LAN"). Erro: $e',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnv.load();

  // Permitir todas as orientações inicialmente
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Inicializar cliente HTTP/JWT da VPS e disponibilizar globalmente
  final apiService = LuditecaApiService();
  await apiService.initialize();
  Get.put(apiService);
  if (kDebugMode && !kIsWeb) {
    try {
      if (Platform.isAndroid) {
        unawaited(_logApiReachability());
      }
    } catch (_) {}
  }

  // Inicializa os controllers
  AppPages.initControllers();

  runApp(const LudiTecaApp());
}

class LudiTecaApp extends StatelessWidget {
  const LudiTecaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<AuthController>(
        init: AuthController(),
        builder: (authController) {
          // Mostrar splash screen durante o carregamento inicial
          if (!authController.initialLoadCompleted) {
            return GetMaterialApp(
              theme: AppTheme.lightTheme,
              debugShowCheckedModeBanner: false,
              home: const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Inicializando...", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            );
          }

          debugPrint(
            'Main: Definindo rota inicial. Autenticado: ${authController.isAuthenticated}',
          );

          final prefs = Get.find<AppPreferencesController>();

          return GetMaterialApp(
            title: 'LudiTeca',
            theme: AppTheme.forId(prefs.appThemeId.value),
            debugShowCheckedModeBanner: false,
            defaultTransition: Transition.fadeIn,
            transitionDuration: const Duration(milliseconds: 180),
            routingCallback: (routing) {
              if (Get.isRegistered<AppShellRouteScope>()) {
                Get.find<AppShellRouteScope>().sync();
              }
            },
            home:
                authController.isAuthenticated
                    ? const HomePage()
                    : const LoginPage(),
            getPages: [
              GetPage(name: '/login', page: () => const LoginPage()),
              GetPage(name: '/home', page: () => const HomePage()),
              GetPage(
                name: '/library',
                page: () => const LibraryPage(),
                binding: BindingsBuilder(() {
                  Get.put(LibraryController());
                }),
              ),
              GetPage(
                name: '/category-books',
                page: () => CategoryBooksPage(category: Get.arguments),
              ),
              ...AppPages.routes, // Adiciona as rotas do AppPages
            ],
            unknownRoute: GetPage(
              name: '/login',
              page: () => const LoginPage(),
            ),
          );
        },
    );
  }
}

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    if (!authController.isAuthenticated) {
      // Evitar ciclos de redirecionamento
      if (ModalRoute.of(context)?.settings.name != '/login') {
        debugPrint(
          'AuthGuard: Usuário não autenticado, redirecionando para login',
        );

        // Redirecionar para a tela de login se não estiver autenticado
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed('/login');
        });
      }
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    debugPrint('AuthGuard: Usuário autenticado, mostrando página protegida');
    return child;
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Bem-vindo à LudiTeca!")));
  }
}
