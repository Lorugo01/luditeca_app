import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/navigation/app_shell_navigator.dart';
import '../../../widgets/app_shell_layout.dart';
import '../../../widgets/app_subpage_header.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_avatar_widget.dart';

/// Perfil principal: avatar, nome, estatísticas. Sem grelha de personagens.
/// Avatares e edição completa → [ProfileEditPage] via «Editar Perfil».
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<ProfileController>()) {
      Get.put(ProfileController(), permanent: true);
    }
    controller = Get.find<ProfileController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadUserProfile();
    });
  }

  Future<void> _uploadPhotoOnly(BuildContext context) async {
    final ok = await controller.pickAndUploadProfileImage(context);
    if (ok && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShellLayout(
      body: Container(
        color: AppLayoutTokens.scaffoldBackground,
        child: Obx(() {
            if (controller.isLoading.value && controller.userName.value.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.error.isNotEmpty && controller.userName.value.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        controller.error.value,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: controller.loadUserProfile,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final level = controller.xpLevel;

            return RefreshIndicator(
              onRefresh: controller.loadUserProfile,
              color: AppLayoutTokens.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  AppShellLayout.scrollBottomPadding(context),
                ),
                child: Column(
                  children: [
                    AppSubpageHeader(
                      title: '👤 Meu Perfil',
                      onBack: () => appSubpageBack(),
                      trailing: IconButton(
                        onPressed: controller.signOut,
                        tooltip: 'Sair',
                        icon: Icon(
                          Icons.logout,
                          color: AppLayoutTokens.textPrimary.withAlpha(180),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        ProfileAvatarWidget(
                          imageUrl: controller.displayAvatarUrl,
                          avatarId: controller.avatarId.value,
                          radius: 56,
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Material(
                            color: AppLayoutTokens.primary,
                            shape: const CircleBorder(),
                            elevation: 3,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => _uploadPhotoOnly(context),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.userName.value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppLayoutTokens.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.roleLabel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: AppLayoutTokens.textPrimary.withAlpha(140),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${controller.userAge.value} anos · ${controller.ageBand.display}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppLayoutTokens.textPrimary.withAlpha(160),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${level.emoji} Nível ${level.level} — ${level.title}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppLayoutTokens.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${level.totalXp} XP · faltam ${level.xpRemaining} para o nível ${level.level + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppLayoutTokens.textPrimary.withAlpha(150),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: level.progress.clamp(0.05, 1.0),
                        minHeight: 10,
                        backgroundColor: AppLayoutTokens.primary.withAlpha(40),
                        color: AppLayoutTokens.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _StatisticsSection(controller: controller),
                    const SizedBox(height: 16),
                    _AchievementsPreview(controller: controller),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Get.toNamed('/profile/edit'),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar Perfil'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: AppLayoutTokens.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
    );
  }
}

/// Cartão de estatísticas — contraste forte em tema claro e escuro.
class _StatisticsSection extends StatelessWidget {
  const _StatisticsSection({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final books = controller.booksRead.value;
      final favs = controller.favorites.value;
      final progress = controller.booksInProgress.value;

      final cardColor = AppLayoutTokens.isDark
          ? const Color(0xFF2A1F4E)
          : const Color(0xFFFFFFFF);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppLayoutTokens.primary.withAlpha(AppLayoutTokens.isDark ? 80 : 50),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(AppLayoutTokens.isDark ? 60 : 20),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: AppLayoutTokens.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Estatísticas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppLayoutTokens.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.menu_book_outlined,
                    value: '$books',
                    label: 'Livros Lidos',
                    onTap: () => _showBooksHistory(context, controller),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.favorite_border,
                    value: '$favs',
                    label: 'Favoritos',
                    onTap: AppShellNavigator.goToFavorites,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.trending_up,
                    value: '$progress',
                    label: 'Progresso',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Future<void> _showBooksHistory(BuildContext context, ProfileController c) async {
    final books = await c.fetchBooksReadHistory();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Histórico de Livros Lidos'),
        content: SizedBox(
          width: 400,
          child: books.isEmpty
              ? const Text('Nenhum livro lido ainda.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: books.length,
                  itemBuilder: (_, index) {
                    final book = books[index];
                    return ListTile(
                      leading: book['cover_image'] != null
                          ? CachedNetworkImage(
                              imageUrl: book['cover_image'],
                              width: 40,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.menu_book),
                      title: Text(book['title'] ?? 'Sem título'),
                      subtitle: Text(book['author'] ?? 'Autor desconhecido'),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fechar')),
        ],
      ),
    );
  }
}

class _AchievementsPreview extends StatelessWidget {
  const _AchievementsPreview({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final unlocked = controller.unlockedAchievementsCount;
      final recent = controller.achievements
          .where((a) => a.unlocked && !a.def.comingSoon)
          .take(3)
          .toList();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppLayoutTokens.elevatedSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppLayoutTokens.subtleBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conquistas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppLayoutTokens.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '$unlocked desbloqueadas',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppLayoutTokens.primary,
                  ),
                ),
              ],
            ),
            if (recent.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in recent)
                    Chip(
                      avatar: Text(a.def.emoji),
                      label: Text(
                        a.def.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppLayoutTokens.textPrimary,
                        ),
                      ),
                      backgroundColor: AppLayoutTokens.primary.withAlpha(28),
                      side: BorderSide(color: AppLayoutTokens.subtleBorder),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.toNamed('/achievements'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppLayoutTokens.primary,
                  side: BorderSide(color: AppLayoutTokens.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Ver todas as conquistas'),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final inner = AppLayoutTokens.isDark
        ? const Color(0xFF1A1433)
        : const Color(0xFFF1F5F9);

    return Material(
      color: inner,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppLayoutTokens.subtleBorder),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppLayoutTokens.primary, size: 26),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppLayoutTokens.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: AppLayoutTokens.textPrimary.withAlpha(200),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
