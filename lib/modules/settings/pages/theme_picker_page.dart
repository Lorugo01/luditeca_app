import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/preferences/app_preferences_controller.dart';
import '../../../core/theme/app_theme_palette.dart';
import '../../../widgets/app_shell_layout.dart';

/// Página de seleção de tema (paridade com o seletor de temas do Play).
class ThemePickerPage extends StatelessWidget {
  const ThemePickerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = Get.find<AppPreferencesController>();

    return AppShellLayout(
      body: Container(
        color: AppLayoutTokens.scaffoldBackground,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onBack: () => Get.back()),
              Expanded(
                child: Obx(() {
                  final selectedId = prefs.appThemeId.value;
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: AppThemeRegistry.families.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final family = AppThemeRegistry.families[index];
                      return _ThemeFamilyCard(
                        family: family,
                        selectedId: selectedId,
                        onSelect: prefs.setAppTheme,
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        children: [
          Material(
            color: AppLayoutTokens.cardBackground,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back, color: AppLayoutTokens.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '🎨 Escolher Tema',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppLayoutTokens.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeFamilyCard extends StatelessWidget {
  const _ThemeFamilyCard({
    required this.family,
    required this.selectedId,
    required this.onSelect,
  });

  final AppThemeFamily family;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final light = AppThemeRegistry.palette(family.lightId);
    final dark = AppThemeRegistry.palette(family.darkId);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppLayoutTokens.cardBackground.withAlpha(120),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Text(family.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  family.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppLayoutTokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _ThemeSwatch(
                  palette: light,
                  selected: selectedId == light.id,
                  onTap: () => onSelect(light.id),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ThemeSwatch(
                  palette: dark,
                  selected: selectedId == dark.id,
                  onTap: () => onSelect(dark.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final AppThemePalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? palette.primary : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withAlpha(40),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _dot(palette.primary),
                  _dot(palette.accent),
                  _dot(palette.highlight),
                  _dot(palette.secondary),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: LinearGradient(
                    colors: [palette.primary, palette.accent],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      palette.variantLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: palette.text,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, size: 18, color: palette.primary)
                  else
                    Icon(
                      Icons.circle_outlined,
                      size: 18,
                      color: palette.text.withAlpha(90),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
