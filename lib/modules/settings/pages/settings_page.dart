import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/controllers/auth_controller.dart';
import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/navigation/app_shell_navigator.dart';
import '../../../core/preferences/app_preferences_controller.dart';
import '../../../core/preferences/layout_option.dart';
import '../../../core/theme.dart';
import '../../../widgets/app_shell_layout.dart';
import '../../profile/pages/profile_page.dart';
import '../widgets/settings_layout_picker_sheet.dart';
import 'settings_offline_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = Get.find<AppPreferencesController>();

    return AppShellLayout(
      body: Container(
        color: AppLayoutTokens.scaffoldBackground,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            children: [
              _SettingsHeader(onBack: AppShellNavigator.goToHome),
              const SizedBox(height: 20),
              _SettingsLinksCard(
                items: [
                  _SettingsLinkItem(
                    emoji: '👤',
                    title: 'Editar Perfil',
                    subtitle: 'Nome, idade e personagem',
                    onTap: () => Get.to(() => const ProfilePage()),
                  ),
                  _SettingsLinkItem(
                    emoji: '🎨',
                    title: 'Temas',
                    subtitle: 'Cores e visual do app',
                    onTap: () => _showThemePicker(context, prefs),
                  ),
                  _SettingsLinkItem(
                    emoji: '🏆',
                    title: 'Conquistas',
                    subtitle: 'Medalhas e badges',
                    onTap: () => Get.to(() => const ProfilePage()),
                  ),
                  _SettingsLinkItem(
                    emoji: '📦',
                    title: 'Conteúdo Offline',
                    subtitle: 'Baixar livros e jogos',
                    onTap: () => Get.to(() => const SettingsOfflinePage()),
                    showDivider: false,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsLayoutShortcuts(prefs: prefs),
              const SizedBox(height: 16),
              _DeleteAccountCard(
                onTap: () => _showDeleteAccountFlow(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, AppPreferencesController prefs) {
  const themes = [
    ('ocean', '🌊 Oceano', 'Azul claro — padrão'),
    ('rose', '🌸 Rosa', 'Rosa e coral'),
    ('forest', '🌿 Floresta', 'Verde e menta'),
  ];

    Get.bottomSheet<void>(
      Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppLayoutTokens.scaffoldBackground,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Temas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppLayoutTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              return Column(
                children: themes.map((t) {
                  final selected = prefs.appThemeId.value == t.$1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: selected ? AppLayoutTokens.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      tileColor: selected
                          ? AppLayoutTokens.primary.withAlpha(36)
                          : AppLayoutTokens.cardBackground,
                      title: Text(t.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(t.$3),
                      trailing: selected
                          ? const Icon(Icons.check_circle, color: AppLayoutTokens.primary)
                          : null,
                      onTap: () async {
                        await prefs.setAppTheme(t.$1);
                        Get.changeTheme(AppTheme.forId(t.$1));
                        Get.back();
                        Get.snackbar(
                          'Tema aplicado',
                          t.$2,
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 2),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _showDeleteAccountFlow(BuildContext context) async {
    var step = 0;
    final inputController = TextEditingController();

    await Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(step == 0 ? 'Excluir conta' : 'Confirmar exclusão'),
            content: step == 0
                ? const Text(
                    'Esta ação apaga os dados locais e encerra a sessão. '
                    'Para remover a conta no servidor, contacte o administrador.',
                  )
                : TextField(
                    controller: inputController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Digite EXCLUIR',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancelar'),
              ),
              if (step == 0)
                FilledButton(
                  onPressed: () => setState(() => step = 1),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC53030)),
                  child: const Text('Entendi'),
                )
              else
                FilledButton(
                  onPressed: inputController.text.trim().toUpperCase() == 'EXCLUIR'
                      ? () async {
                          Get.back();
                          final prefs = Get.find<AppPreferencesController>();
                          await prefs.clearLocalAppData();
                          await Get.find<AuthController>().signOut();
                          Get.offAllNamed('/login');
                          Get.snackbar(
                            'Conta',
                            'Sessão encerrada e dados locais apagados.',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFC53030)),
                  child: const Text('Excluir'),
                ),
            ],
          );
        },
      ),
    );

    inputController.dispose();
  }
}

class _SettingsLayoutShortcuts extends StatelessWidget {
  const _SettingsLayoutShortcuts({required this.prefs});

  final AppPreferencesController prefs;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Lê observáveis aqui (fora do LayoutBuilder) para o GetX reagir.
      final menuLabel = prefs.menuLayoutLabel;
      final activitiesLabel = prefs.activitiesLayoutLabel;
      final libraryLabel = prefs.libraryLayoutLabel;
      final menuId = prefs.menuLayoutId.value;
      final activitiesId = prefs.activitiesLayoutId.value;
      final libraryId = prefs.libraryLayoutId.value;

      return LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;
          final children = [
            _LayoutShortcutCard(
              icon: Icons.grid_view_rounded,
              title: 'Layout do Menu',
              subtitle: menuLabel,
              onTap: () => showSettingsLayoutPicker(
                title: 'Layout do Menu Principal',
                options: kMenuLayoutOptions,
                selectedId: menuId,
                onSelected: prefs.setMenuLayout,
              ),
            ),
            _LayoutShortcutCard(
              icon: Icons.grid_view_rounded,
              title: 'Layout Atividades',
              subtitle: activitiesLabel,
              onTap: () => showSettingsLayoutPicker(
                title: 'Layout das Atividades',
                options: kActivitiesLayoutOptions,
                selectedId: activitiesId,
                onSelected: prefs.setActivitiesLayout,
              ),
            ),
            _LayoutShortcutCard(
              icon: Icons.menu_book_outlined,
              title: 'Layout da Biblioteca',
              subtitle: libraryLabel,
              onTap: () => showSettingsLayoutPicker(
                title: 'Layout da Biblioteca',
                options: kLibraryLayoutOptions,
                selectedId: libraryId,
                onSelected: prefs.setLibraryLayout,
              ),
            ),
          ];

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: children[i]),
                ],
              ],
            );
          }

          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                children[i],
              ],
            ],
          );
        },
      );
    });
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppLayoutTokens.cardBackground,
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onBack,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(Icons.arrow_back, color: AppLayoutTokens.textPrimary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          '⚙️ Configurações',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppLayoutTokens.primary,
          ),
        ),
      ],
    );
  }
}

class _SettingsLinkItem {
  const _SettingsLinkItem({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;
}

class _SettingsLinksCard extends StatelessWidget {
  const _SettingsLinksCard({required this.items});

  final List<_SettingsLinkItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppLayoutTokens.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppLayoutTokens.primary.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++)
              _SettingsLinkTile(
                item: items[i],
                showDivider: items[i].showDivider && i < items.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _SettingsLinkTile extends StatelessWidget {
  const _SettingsLinkTile({
    required this.item,
    required this.showDivider,
  });

  final _SettingsLinkItem item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppLayoutTokens.primary.withAlpha(36),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(item.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppLayoutTokens.textPrimary,
                          ),
                        ),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppLayoutTokens.textPrimary.withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppLayoutTokens.textPrimary.withAlpha(102),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 72,
            color: AppLayoutTokens.primary.withAlpha(36),
          ),
      ],
    );
  }
}

class _LayoutShortcutCard extends StatelessWidget {
  const _LayoutShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppLayoutTokens.cardBackground,
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppLayoutTokens.primary.withAlpha(36)),
            boxShadow: [
              BoxShadow(
                color: AppLayoutTokens.primary.withAlpha(30),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppLayoutTokens.primary.withAlpha(36),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppLayoutTokens.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppLayoutTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppLayoutTokens.textPrimary.withAlpha(153),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountCard extends StatelessWidget {
  const _DeleteAccountCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF5F5),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFED7D7)),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFC53030)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Excluir Conta',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFFC53030),
                      ),
                    ),
                    Text(
                      'Permanente e irreversível',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFC53030).withAlpha(179),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
