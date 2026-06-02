import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/layout/app_layout_tokens.dart';
import '../core/navigation/app_shell_navigator.dart';
import '../core/navigation/app_shell_route_scope.dart';

/// Item da navegação principal (equivalente a `NAV_ITEMS` do `BottomNav.jsx` do Play,
/// com **Favoritos** extra para não regressar funcionalidade do app).
class _NavItem {
  const _NavItem({
    required this.route,
    required this.emoji,
    required this.label,
    required this.activeRoots,
    this.shortLabel,
  });

  final String route;
  final String emoji;
  final String label;

  /// Rótulo curto quando a barra inferior não tem largura (evita "Biblio...").
  final String? shortLabel;

  /// Rotas em que este item deve aparecer como activo.
  final List<String> activeRoots;
}

const List<_NavItem> _kNavItems = [
  _NavItem(
    route: '/home',
    emoji: '🏠',
    label: 'Início',
    activeRoots: ['/home'],
  ),
  _NavItem(
    route: '/library',
    emoji: '📚',
    label: 'Biblioteca',
    shortLabel: 'Livros',
    activeRoots: ['/library', '/category-books'],
  ),
  _NavItem(
    route: '/favorites',
    emoji: '❤️',
    label: 'Favoritos',
    shortLabel: 'Favs',
    activeRoots: ['/favorites'],
  ),
  _NavItem(
    route: '/activities',
    emoji: '🎮',
    label: 'Atividades',
    shortLabel: 'Jogos',
    activeRoots: ['/activities'],
  ),
  _NavItem(
    route: '/settings',
    emoji: '⚙️',
    label: 'Config.',
    activeRoots: kSettingsActiveRoots,
  ),
];

class ResponsiveNavigation extends StatefulWidget {
  const ResponsiveNavigation({super.key, this.showFavorites = false});

  static const double railExpandedWidth = 232;
  static const double railCollapsedWidth = 84;

  final bool showFavorites;

  @override
  State<ResponsiveNavigation> createState() => _ResponsiveNavigationState();
}

class _ResponsiveNavigationState extends State<ResponsiveNavigation> {
  bool _railExpanded = true;

  @override
  void initState() {
    super.initState();
    if (widget.showFavorites) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppShellNavigator.goToFavorites();
      });
    }
  }

  int _selectedIndex(String route) {
    for (var i = 0; i < _kNavItems.length; i++) {
      if (_kNavItems[i].activeRoots.any(
            (root) => route == root || route.startsWith('$root/'),
          )) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final scope = Get.find<AppShellRouteScope>();
    return Obx(() {
      final orientation = MediaQuery.orientationOf(context);
      final isLandscape = orientation == Orientation.landscape;
      final selectedIndex = _selectedIndex(scope.route.value);

      if (isLandscape) {
        return _buildRail(context, selectedIndex);
      }
      return _buildBottomBar(context, selectedIndex);
    });
  }

  Widget _buildRail(BuildContext context, int selectedIndex) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: _railExpanded
          ? ResponsiveNavigation.railExpandedWidth
          : ResponsiveNavigation.railCollapsedWidth,
      decoration: BoxDecoration(
        color: AppLayoutTokens.navSurface,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppLayoutTokens.primary.withAlpha(40),
            blurRadius: 16,
            offset: const Offset(2, 0),
          ),
        ],
        border: Border(
          right: BorderSide(color: AppLayoutTokens.navBorder, width: 1),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
              child: _railExpanded
                  ? Row(
                      children: [
                        const Text('📖', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'LudiTeca',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppLayoutTokens.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _RailToggleButton(
                          expanded: _railExpanded,
                          onPressed: () =>
                              setState(() => _railExpanded = !_railExpanded),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📖', style: TextStyle(fontSize: 24)),
                        _RailToggleButton(
                          expanded: _railExpanded,
                          onPressed: () =>
                              setState(() => _railExpanded = !_railExpanded),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < _kNavItems.length; i++)
              _RailTile(
                item: _kNavItems[i],
                expanded: _railExpanded,
                selected: i == selectedIndex,
                onTap: () => _onTabTap(i),
              ),
            const Spacer(),
            if (_railExpanded)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Luditeca',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppLayoutTokens.textPrimary.withAlpha(180),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, int selectedIndex) {
    final width = MediaQuery.sizeOf(context).width;
    final showNavLabels = width >= 400;

    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppLayoutTokens.navSurface,
          borderRadius: AppLayoutTokens.barTopRadius,
          border: Border(
            top: BorderSide(color: AppLayoutTokens.navBorder, width: 1),
          ),
          boxShadow: AppLayoutTokens.navTopShadow,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 6,
              top: 8,
            ),
            child: Row(
              children: [
                for (var i = 0; i < _kNavItems.length; i++)
                  Expanded(
                    child: _BottomTile(
                      item: _kNavItems[i],
                      selected: i == selectedIndex,
                      showLabel: showNavLabels,
                      onTap: () => _onTabTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTabTap(int index) {
    final item = _kNavItems[index];
    AppShellNavigator.goToTab(
      route: item.route,
      activeRoots: item.activeRoots,
    );
  }
}

/// Botão compacto para expandir/colapsar o rail (evita overflow em 84px).
class _RailToggleButton extends StatelessWidget {
  const _RailToggleButton({
    required this.expanded,
    required this.onPressed,
  });

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      iconSize: 22,
      icon: Icon(
        expanded ? Icons.chevron_left : Icons.chevron_right,
        color: AppLayoutTokens.primary,
      ),
    );
  }
}

class _RailTile extends StatelessWidget {
  const _RailTile({
    required this.item,
    required this.expanded,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool expanded;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.white : Colors.white.withAlpha(77);
    final fg = selected ? AppLayoutTokens.primary : AppLayoutTokens.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: selected ? null : onTap,
          splashColor: selected ? Colors.transparent : null,
          highlightColor: selected ? Colors.transparent : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppLayoutTokens.primary.withAlpha(120) : Colors.transparent,
              ),
            ),
            child:
                expanded
                    ? Row(
                      children: [
                        Text(item.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                              color: fg,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    )
                    : Center(child: Text(item.emoji, style: const TextStyle(fontSize: 24))),
          ),
        ),
      ),
    );
  }
}

class _BottomTile extends StatelessWidget {
  const _BottomTile({
    required this.item,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = AppLayoutTokens.primary;
    final textColor = selected ? primary : AppLayoutTokens.textPrimary;
    final width = MediaQuery.sizeOf(context).width;
    final label = showLabel
        ? (width < 520 && item.shortLabel != null ? item.shortLabel! : item.label)
        : null;

    return Tooltip(
      message: item.label,
      child: InkWell(
        onTap: selected ? null : onTap,
        splashColor: selected ? Colors.transparent : null,
        highlightColor: selected ? Colors.transparent : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected)
                Container(
                  width: 28,
                  height: 3,
                  margin: EdgeInsets.only(bottom: showLabel ? 4 : 2),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                )
              else
                SizedBox(height: showLabel ? 7 : 5),
              Text(
                item.emoji,
                style: TextStyle(
                  fontSize: showLabel ? 22 : 24,
                  height: 1,
                  color: selected ? null : Colors.grey.shade600,
                ),
              ),
              if (label != null) ...[
                const SizedBox(height: 2),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: width < 520 ? 9 : 10,
                    fontWeight: FontWeight.w800,
                    color: textColor.withAlpha(selected ? 255 : 140),
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
