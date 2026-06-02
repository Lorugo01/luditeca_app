import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/navigation/app_shell_navigator.dart';
import '../../../core/utils/app_messenger.dart';
import '../../../widgets/app_shell_layout.dart';
import '../../../widgets/app_subpage_header.dart';
import '../../reader/services/book_offline_cache.dart';

/// Gestão de conteúdo offline / cache local.
class SettingsOfflinePage extends StatefulWidget {
  const SettingsOfflinePage({super.key});

  @override
  State<SettingsOfflinePage> createState() => _SettingsOfflinePageState();
}

class _SettingsOfflinePageState extends State<SettingsOfflinePage> {
  List<OfflineBookEntry> _books = [];
  int _totalBytes = 0;
  int _prefsKeys = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final books = await BookOfflineCache.instance.listEntries();
    final total = await BookOfflineCache.instance.totalBytes();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _books = books;
      _totalBytes = total;
      _prefsKeys = prefs.getKeys().length;
      _loading = false;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
    AppMessenger.success('Progresso de leitura local foi apagado.', title: 'Cache limpo');
    await _refresh();
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _removeBook(OfflineBookEntry entry) async {
    final confirm = await _confirmDialog(
      title: 'Remover do dispositivo?',
      message:
          'O livro «${entry.title}» deixará de estar disponível offline '
          '(${entry.sizeLabel}).',
      confirmLabel: 'Remover',
    );
    if (confirm != true) return;
    await BookOfflineCache.instance.removeBook(entry.id);
    if (!mounted) return;
    AppMessenger.success('Conteúdo offline apagado.', title: 'Removido');
    await _refresh();
  }

  Future<void> _clearAllOffline() async {
    final confirm = await _confirmDialog(
      title: 'Apagar todos os livros offline?',
      message:
          'Serão removidos ${_books.length} livro(s) '
          '(${_formatBytes(_totalBytes)}). Na próxima leitura voltam a ser transferidos.',
      confirmLabel: 'Apagar tudo',
    );
    if (confirm != true) return;
    await BookOfflineCache.instance.clearAllBooks();
    if (!mounted) return;
    AppMessenger.success(
      'Todos os livros guardados no dispositivo foram apagados.',
      title: 'Offline limpo',
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
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
              title: '📦 Conteúdo Offline',
              onBack: () => appSubpageBack(),
            ),
            const SizedBox(height: 20),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else ...[
                _InfoCard(
                  title: 'Livros no dispositivo',
                  body:
                      '${_books.length} livro(s) guardado(s) para leitura sem voltar a transferir imagens. '
                      'Espaço usado: ${_formatBytes(_totalBytes)}.',
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Outros dados locais',
                  body:
                      'Progresso de aventuras e preferências: $_prefsKeys chaves no armazenamento.',
                ),
                if (_books.isEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Abra um livro na biblioteca para o guardar aqui automaticamente na primeira leitura.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppLayoutTokens.textPrimary.withAlpha(179),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  ..._books.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _OfflineBookTile(
                        entry: b,
                        onRemove: () => _removeBook(b),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _books.isEmpty ? null : _clearAllOffline,
                  icon: const Icon(Icons.folder_delete_outlined),
                  label: const Text('Apagar todos os livros offline'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppLayoutTokens.primary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
    );
  }
}

class _OfflineBookTile extends StatelessWidget {
  const _OfflineBookTile({
    required this.entry,
    required this.onRemove,
  });

  final OfflineBookEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppLayoutTokens.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppLayoutTokens.primary.withAlpha(24),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.offline_pin, color: AppLayoutTokens.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppLayoutTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.sizeLabel} · ${entry.imageCount} imagem(ns) · ${entry.kind}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppLayoutTokens.textPrimary.withAlpha(160),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remover offline',
          ),
        ],
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
            style: TextStyle(
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
