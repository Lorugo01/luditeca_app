import 'package:flutter/material.dart';
import '../core/layout/app_layout_tokens.dart';
import 'responsive_navigation.dart';

/// *Shell* principal do app autenticado: fundo «Oceano», rail em landscape
/// e barra inferior em portrait — mesma base que o Play (BottomNav + área de conteúdo).
class AppShellLayout extends StatelessWidget {
  const AppShellLayout({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppLayoutTokens.scaffoldBackground,
      appBar: appBar,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLandscape) const ResponsiveNavigation(),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: isLandscape ? null : const ResponsiveNavigation(),
      floatingActionButton: floatingActionButton,
    );
  }
}
