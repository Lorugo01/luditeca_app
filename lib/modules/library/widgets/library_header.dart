import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/layout/app_layout_tokens.dart';
import '../controllers/library_controller.dart';
import 'library_layout.dart';

/// Cabeçalho da biblioteca (paridade com `Library.jsx` do Play).
class LibraryHeader extends StatelessWidget {
  const LibraryHeader({super.key, required this.controller});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    final compact = LibraryLayout.isCompact(context);
    final horizontalPad = compact ? 10.0 : 16.0;
    final titleSize = compact ? 22.0 : (LibraryLayout.isMedium(context) ? 24.0 : 26.0);
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppLayoutTokens.primary, AppLayoutTokens.accent],
        ),
        boxShadow: [
          BoxShadow(
            color: AppLayoutTokens.primary.withAlpha(64),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPad,
          topInset + 10,
          horizontalPad,
          compact ? 12 : 16,
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 10 : 14),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(36),
                  borderRadius: BorderRadius.circular(compact ? 20 : 28),
                  border: Border.all(color: Colors.white.withAlpha(61)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: compact ? 36 : 40,
                          height: compact ? 36 : 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(46),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withAlpha(61)),
                          ),
                          child: Text('📚', style: TextStyle(fontSize: compact ? 18 : 22)),
                        ),
                        SizedBox(width: compact ? 8 : 12),
                        Expanded(
                          child: Text(
                            'Biblioteca',
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            softWrap: false,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleSize,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    TextField(
                      onChanged: controller.setSearch,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 13 : 14,
                      ),
                      decoration: InputDecoration(
                        isDense: compact,
                        hintText: compact
                            ? 'Buscar livros…'
                            : 'Buscar por título, autor ou descrição...',
                        hintStyle: TextStyle(
                          color: Colors.white.withAlpha(179),
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 12 : 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withAlpha(200),
                          size: compact ? 20 : 22,
                        ),
                        filled: true,
                        fillColor: Colors.white.withAlpha(46),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.white.withAlpha(61)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.white.withAlpha(61)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: Colors.white, width: 1.5),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: compact ? 10 : 12,
                          horizontal: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 8 : 12),
              Obx(
                () => _FilterTabs(
                  active: controller.activeFilter.value,
                  onSelect: controller.setFilter,
                  compact: compact,
                ),
              ),
            ],
        ),
      ),
    );
  }
}

class _FilterTabData {
  const _FilterTabData(this.filter, this.emoji, this.label);

  final LibraryBookFilter filter;
  final String emoji;
  final String label;
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.active,
    required this.onSelect,
    required this.compact,
  });

  final LibraryBookFilter active;
  final void Function(LibraryBookFilter) onSelect;
  final bool compact;

  static const _tabs = [
    _FilterTabData(LibraryBookFilter.all, '📚', 'Todos'),
    _FilterTabData(LibraryBookFilter.animated, '✨', 'Animados'),
    _FilterTabData(LibraryBookFilter.interactive, '🔀', 'Interativos'),
    _FilterTabData(LibraryBookFilter.digital, '📄', 'PDF / EPUB'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(36),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(61)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _tabs.map((tab) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _chip(context, tab),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, _FilterTabData tab) {
    final selected = active == tab.filter;
    final text = '${tab.emoji} ${tab.label}';

    return Material(
      color: selected ? Colors.white : Colors.white.withAlpha(46),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => onSelect(tab.filter),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: compact ? 8 : 10,
          ),
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w800,
              color: selected ? AppLayoutTokens.primary : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
