import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/controllers/auth_controller.dart';
import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/navigation/app_shell_navigator.dart';
import '../../../core/preferences/app_preferences_controller.dart';
import '../../../core/preferences/layout_option.dart';
import '../../../widgets/app_shell_layout.dart';
import '../../../widgets/app_subpage_header.dart';
import '../widgets/settings_layout_picker_sheet.dart';
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = Get.find<AppPreferencesController>();

    return AppShellLayout(
      body: Container(
        color: AppLayoutTokens.scaffoldBackground,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            AppShellLayout.scrollBottomPadding(context),
          ),
          children: [
            AppSubpageHeader(
              title: '⚙️ Configurações',
              onBack: AppShellNavigator.goToHome,
            ),
              const SizedBox(height: 20),
              _SettingsLinksCard(
                items: [
                  _SettingsLinkItem(
                    emoji: '👤',
                    title: 'Meu Perfil',
                    subtitle: 'Estatísticas, nome e nível',
                    onTap: () => Get.toNamed('/profile'),
                  ),
                  _SettingsLinkItem(
                    emoji: '🎨',
                    title: 'Temas',
                    subtitle: 'Cores e visual do app',
                    onTap: () => Get.toNamed('/settings/themes'),
                  ),
                  _SettingsLinkItem(
                    emoji: '🏆',
                    title: 'Conquistas',
                    subtitle: 'Medalhas e badges',
                    onTap: () => Get.toNamed('/achievements'),
                  ),
                  _SettingsLinkItem(
                    emoji: '📦',
                    title: 'Conteúdo Offline',
                    subtitle: 'Baixar livros e jogos',
                    onTap: () => Get.toNamed('/settings/offline'),
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
    );
  }

  Future<void> _showDeleteAccountFlow(BuildContext context) async {
    final passwordController = TextEditingController();
    final auth = Get.find<AuthController>();
    final email = auth.currentUser?['email']?.toString() ?? '';

    var obscure = true;
    var loading = false;
    String? errorText;

    await Get.dialog<void>(
      StatefulBuilder(
        builder: (context, setState) {
          Future<void> confirm() async {
            final pwd = passwordController.text;
            if (pwd.isEmpty) {
              setState(() => errorText = 'Informe a senha.');
              return;
            }
            if (email.isEmpty) {
              setState(() => errorText = 'Não foi possível identificar a conta.');
              return;
            }
            setState(() {
              loading = true;
              errorText = null;
            });

            final ok = await auth.signIn(email, pwd);
            if (!ok) {
              setState(() {
                loading = false;
                errorText = 'Senha incorreta.';
              });
              return;
            }

            Get.back();
            final prefs = Get.find<AppPreferencesController>();
            await prefs.clearLocalAppData();
            await auth.signOut();
            Get.offAllNamed('/login');
            Get.snackbar(
              'Conta',
              'Sessão encerrada e dados locais apagados.',
              snackPosition: SnackPosition.BOTTOM,
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Excluir conta'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirme a sua senha para apagar os dados locais e '
                  'encerrar a sessão.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscure,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    border: const OutlineInputBorder(),
                    errorText: errorText,
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                  onSubmitted: (_) => confirm(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Get.back(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: loading ? null : confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC53030),
                ),
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Excluir'),
              ),
            ],
          );
        },
      ),
    );

    passwordController.dispose();
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
                          style: TextStyle(
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
                      style: TextStyle(
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
