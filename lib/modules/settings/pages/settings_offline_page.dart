import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/navigation/app_shell_navigator.dart';
import '../../../widgets/app_shell_layout.dart';

/// Gestão de conteúdo offline / cache local.
class SettingsOfflinePage extends StatefulWidget {
  const SettingsOfflinePage({super.key});

  @override
  State<SettingsOfflinePage> createState() => _SettingsOfflinePageState();
}

class _SettingsOfflinePageState extends State<SettingsOfflinePage> {
  int _localKeys = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _localKeys = prefs.getKeys().length;
      _loading = false;
    });
  }

  Future<void> _clearReadingCache() async {
    final prefs = await SharedPreferences.getInstance();
    final toRemove = prefs.getKeys().where((k) {
      return k.contains('progress') ||
          k.contains('reading') ||
          k.contains('reader') ||
          k.contains('interactive');
    });
    for (final key in toRemove) {
      await prefs.remove(key);
    }
    if (!mounted) return;
    Get.snackbar(
      'Cache limpo',
      'Progresso de leitura local foi apagado.',
      snackPosition: SnackPosition.BOTTOM,
    );
    await _refreshStats();
  }

  @override
  Widget build(BuildContext context) {
    return AppShellLayout(
      body: Container(
        color: AppLayoutTokens.scaffoldBackground,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _BackChip(onTap: () => Get.back()),
                  const SizedBox(width: 12),
                  const Text(
                    '📦 Conteúdo Offline',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppLayoutTokens.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                _InfoCard(
                  title: 'Estado',
                  body:
                      'Os livros são lidos online pela API. '
                      'Esta área gere dados guardados no dispositivo '
                      '($_localKeys chaves no armazenamento local).',
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Favoritos',
                  body:
                      'Os favoritos sincronizam com a sua conta quando há ligação à internet.',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _clearReadingCache,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Limpar progresso local'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppLayoutTokens.primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: AppShellNavigator.goToLibrary,
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Ir para a Biblioteca'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BackChip extends StatelessWidget {
  const _BackChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppLayoutTokens.cardBackground,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.arrow_back, color: AppLayoutTokens.textPrimary),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppLayoutTokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppLayoutTokens.primary.withAlpha(30),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppLayoutTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppLayoutTokens.textPrimary.withAlpha(179),
            ),
          ),
        ],
      ),
    );
  }
}
