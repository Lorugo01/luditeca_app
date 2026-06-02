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

  /// Margem mínima no conteúdo (Windows/desktop não reporta notch no [SafeArea]).
  static const EdgeInsets _contentMinimum = EdgeInsets.fromLTRB(12, 12, 12, 8);

  /// Espaço inferior para scroll acima da barra inferior (portrait).
  static double scrollBottomPadding(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    final inset = MediaQuery.paddingOf(context).bottom;
    return inset + (isLandscape ? 24 : 88);
  }

  static Widget safeContent({
    required BuildContext context,
    required Widget child,
    required bool isLandscape,
  }) {
    return SafeArea(
      minimum: _contentMinimum,
      left: !isLandscape,
      right: true,
      top: true,
      bottom: isLandscape,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final safeBody = safeContent(
      context: context,
      isLandscape: isLandscape,
      child: body,
    );

    return Scaffold(
      backgroundColor: AppLayoutTokens.scaffoldBackground,
      appBar: appBar,
      body: isLandscape
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ResponsiveNavigation(),
                Expanded(
                  child: ClipRect(
                    clipBehavior: Clip.hardEdge,
                    child: safeBody,
                  ),
                ),
              ],
            )
          : safeBody,
      bottomNavigationBar: isLandscape ? null : const ResponsiveNavigation(),
      floatingActionButton: floatingActionButton,
    );
  }
}
