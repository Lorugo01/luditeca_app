import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/navigation/app_shell_navigator.dart';
import '../../../core/preferences/app_preferences_controller.dart';
import '../../../widgets/app_shell_layout.dart';

/// Reserva de espaço para o módulo de atividades (paridade com o Luditeca Play).
class ActivitiesPlaceholderPage extends StatelessWidget {
  const ActivitiesPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = Get.find<AppPreferencesController>();

    return AppShellLayout(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Obx(() {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎮', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(
                    'Atividades',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppLayoutTokens.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Em breve: jogos e actividades ligados à Luditeca.\n'
                    'Layout escolhido: ${prefs.activitiesLayoutLabel}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppLayoutTokens.textPrimary.withAlpha(200),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: AppShellNavigator.goToSettings,
                    child: const Text('Alterar layout nas Configurações'),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
