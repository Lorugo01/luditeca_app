import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/layout/app_layout_tokens.dart';
import '../core/navigation/app_shell_navigator.dart';

/// Volta na pilha GetX ou abre a aba de configurações (subpáginas do shell).
void appSubpageBack({String fallbackRoute = '/settings'}) {
  final navigator = Get.key.currentState;
  if (navigator != null && navigator.canPop()) {
    Get.back();
    return;
  }
  switch (fallbackRoute) {
    case '/home':
      AppShellNavigator.goToHome();
      break;
    case '/settings':
      AppShellNavigator.goToSettings();
      break;
    default:
      AppShellNavigator.goToSettings();
  }
}

/// Cabeçalho com botão voltar (subpáginas: perfil, temas, conquistas, etc.).
class AppSubpageHeader extends StatelessWidget {
  const AppSubpageHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppSubpageBackButton(onBack: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppLayoutTokens.primary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppLayoutTokens.textPrimary,
                  ),
                  child: subtitle!,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AppSubpageBackButton extends StatelessWidget {
  const AppSubpageBackButton({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
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
    );
  }
}
