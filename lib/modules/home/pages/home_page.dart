import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/controllers/auth_controller.dart';
import '../../../core/layout/app_layout_tokens.dart';
import '../../../widgets/app_shell_layout.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_continue_section.dart';
import '../widgets/home_menu_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final HomeController homeController;

  @override
  void initState() {
    super.initState();
    Get.find<AuthController>();
    homeController = Get.put(HomeController());
    if (!Get.isRegistered<ProfileController>()) {
      Get.lazyPut(() => ProfileController(), fenix: true);
    }
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      homeController.refreshData();
      final profile = Get.find<ProfileController>();
      if (!profile.isLoading.value && profile.userName.value.isEmpty) {
        profile.loadUserProfile();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      homeController.refreshData();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return AppShellLayout(
      body: Stack(
        children: [
          _HomeBackground(),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: homeController.refreshData,
              color: AppLayoutTokens.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: HomeContinueSection(controller: homeController),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    sliver: const SliverToBoxAdapter(child: HomeMenuSection()),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom + 88,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPad + 8, 16, 8),
      child: Column(
        children: [
          const Text(
            'Luditeca',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppLayoutTokens.primary,
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  color: Color(0x440EA5E9),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sua biblioteca interativa! ✨',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppLayoutTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _HomeProfileBadge(),
        ],
      ),
    );
  }
}

class _HomeBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x660EA5E9),
            Color(0x3338BDF8),
            AppLayoutTokens.scaffoldBackground,
          ],
          stops: [0.0, 0.35, 0.72],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: _bubble(180, AppLayoutTokens.primary.withAlpha(77)),
          ),
          Positioned(
            bottom: 120,
            left: -50,
            child: _bubble(200, AppLayoutTokens.accent.withAlpha(51)),
          ),
          Positioned(
            top: 120,
            left: 24,
            child: _bubble(32, AppLayoutTokens.accent.withAlpha(102)),
          ),
          Positioned(
            bottom: 200,
            right: 40,
            child: _bubble(20, AppLayoutTokens.primary.withAlpha(77)),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _HomeProfileBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final profileCtrl = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : null;

    return Obx(() {
      final user = auth.currentUser;
      final profileName = profileCtrl?.userName.value ?? '';
      final displayName = profileName.isNotEmpty
          ? profileName
          : (user?['name']?.toString().isNotEmpty == true
              ? user!['name'].toString()
              : _nameFromEmail(user?['email']?.toString()));

      final booksRead = profileCtrl?.booksRead.value ?? 0;
      final xpTotal = booksRead * 100;
      final level = _levelFromBooks(booksRead);
      final progressPct = (booksRead % 5) / 5.0;

      final avatarUrl = profileCtrl?.icone.value ?? '';

      return Column(
        children: [
          _Avatar(url: avatarUrl, name: displayName),
          const SizedBox(height: 6),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppLayoutTokens.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${level.emoji} Nível ${level.level} — ${level.title}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppLayoutTokens.textPrimary.withAlpha(179),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 200,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progressPct.clamp(0.05, 1.0),
                minHeight: 8,
                backgroundColor: AppLayoutTokens.primary.withAlpha(36),
                color: AppLayoutTokens.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$xpTotal XP total · $xpTotal XP disponível',
            style: TextStyle(
              fontSize: 11,
              color: AppLayoutTokens.textPrimary.withAlpha(128),
            ),
          ),
        ],
      );
    });
  }

  String _nameFromEmail(String? email) {
    if (email == null || !email.contains('@')) return 'Leitor';
    final part = email.split('@').first;
    if (part.isEmpty) return 'Leitor';
    return part[0].toUpperCase() + part.substring(1);
  }

  _LevelInfo _levelFromBooks(int booksRead) {
    if (booksRead >= 20) {
      return const _LevelInfo('🌟', 5, 'Super Leitor');
    }
    if (booksRead >= 10) {
      return const _LevelInfo('📚', 4, 'Leitor Avançado');
    }
    if (booksRead >= 5) {
      return const _LevelInfo('🚀', 3, 'Explorador');
    }
    if (booksRead >= 2) {
      return const _LevelInfo('🌱', 2, 'Leitor Curioso');
    }
    return const _LevelInfo('🌱', 1, 'Leitor Iniciante');
  }
}

class _LevelInfo {
  const _LevelInfo(this.emoji, this.level, this.title);
  final String emoji;
  final int level;
  final String title;
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});

  final String url;
  final String name;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (url.isNotEmpty) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          url,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      );
    } else {
      child = _fallback();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _fallback() {
    return Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '👤',
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }
}
