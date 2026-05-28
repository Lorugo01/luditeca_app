import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/navigation/app_shell_navigator.dart';
import '../../../core/preferences/app_preferences_controller.dart';
import '../../profile/pages/profile_page.dart';
import '../widgets/home_menu_card.dart';

/// Secção do menu principal na home (respeita layout das configurações).
class HomeMenuSection extends StatelessWidget {
  const HomeMenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = Get.find<AppPreferencesController>();
    final items = _menuItems();

    return Obx(() {
      final layoutId = prefs.menuLayoutId.value;
      final width = MediaQuery.sizeOf(context).width;

      switch (layoutId) {
        case 'list':
          return Column(
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HomeMenuListTile(item: item),
                ),
            ],
          );
        case 'slide':
          return SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return SizedBox(
                  width: 140,
                  child: HomeMenuCard(
                    label: item.label,
                    emoji: item.emoji,
                    gradient: item.gradient,
                    shadowTint: item.shadowColor,
                    onTap: item.onTap,
                  ),
                );
              },
            ),
          );
        case 'grid-large':
          final crossAxisCount = width >= 700 ? 2 : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: crossAxisCount == 1 ? 2.8 : 1.35,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _HomeMenuLargeTile(item: items[index]),
          );
        default:
          final crossAxisCount = width >= 900 ? 4 : (width >= 560 ? 3 : 2);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.92,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return HomeMenuCard(
                label: item.label,
                emoji: item.emoji,
                gradient: item.gradient,
                shadowTint: item.shadowColor,
                onTap: item.onTap,
              );
            },
          );
      }
    });
  }

  List<_HomeMenuItem> _menuItems() {
    return [
      _HomeMenuItem(
        label: 'Minha Biblioteca',
        emoji: '📚',
        gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
        shadowColor: const Color(0xFF0EA5E9),
        onTap: AppShellNavigator.goToLibrary,
      ),
      _HomeMenuItem(
        label: 'Minha Lista',
        emoji: '❤️',
        gradient: const LinearGradient(colors: [Color(0xFFFF6B8A), Color(0xFFFF4499)]),
        shadowColor: const Color(0xFFFF6B8A),
        onTap: AppShellNavigator.goToFavorites,
      ),
      _HomeMenuItem(
        label: 'Atividades & Jogos',
        emoji: '🎮',
        gradient: const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF0EA5E9)]),
        shadowColor: const Color(0xFF22C55E),
        onTap: AppShellNavigator.goToActivities,
      ),
      _HomeMenuItem(
        label: 'Conquistas',
        emoji: '🏆',
        gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFF97316)]),
        shadowColor: const Color(0xFFF59E0B),
        onTap: () => Get.to(() => const ProfilePage()),
      ),
      _HomeMenuItem(
        label: 'Loja de Cosméticos',
        emoji: '✨',
        gradient: const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF0EA5E9)]),
        shadowColor: const Color(0xFF14B8A6),
        onTap: () => Get.to(() => const ProfilePage()),
      ),
      _HomeMenuItem(
        label: 'Configurações',
        emoji: '⚙️',
        gradient: const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFF6366F1)]),
        shadowColor: const Color(0xFF9333EA),
        onTap: AppShellNavigator.goToSettings,
      ),
    ];
  }
}

class _HomeMenuItem {
  const _HomeMenuItem({
    required this.label,
    required this.emoji,
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final Gradient gradient;
  final Color shadowColor;
  final VoidCallback onTap;
}

class _HomeMenuListTile extends StatelessWidget {
  const _HomeMenuListTile({required this.item});

  final _HomeMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppLayoutTokens.cardBackground,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: item.gradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppLayoutTokens.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppLayoutTokens.textPrimary.withAlpha(102)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeMenuLargeTile extends StatelessWidget {
  const _HomeMenuLargeTile({required this.item});

  final _HomeMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppLayoutTokens.cardBackground,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: item.gradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(item.emoji, style: const TextStyle(fontSize: 32)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppLayoutTokens.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
