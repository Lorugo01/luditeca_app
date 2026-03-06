import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'core/services/supabase_service.dart';
import 'core/theme.dart';
import 'core/controllers/auth_controller.dart';
import 'core/controllers/orientation_controller.dart';
import 'core/pages/login_page.dart';
import 'modules/home/pages/home_page.dart';
import 'modules/library/pages/library_page.dart';
import 'modules/library/pages/category_books_page.dart';
import 'modules/library/controllers/library_controller.dart';
import 'routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Permitir todas as orientações inicialmente
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Inicializar o Supabase e disponibilizar globalmente
  final supabaseService = SupabaseService();
  await supabaseService.initialize();
  Get.put(supabaseService); // Adicionando o serviço ao GetX

  // Inicializa os controllers
  AppPages.initControllers();

  runApp(const LudiTecaApp());
}

class LudiTecaApp extends StatelessWidget {
  const LudiTecaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrientationController()),
      ],
      child: GetX<AuthController>(
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

          return GetMaterialApp(
            title: 'LudiTeca',
            theme: AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
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
      ),
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
