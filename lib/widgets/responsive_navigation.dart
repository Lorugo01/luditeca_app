import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResponsiveNavigation extends StatefulWidget {
  final bool showFavorites;

  const ResponsiveNavigation({super.key, this.showFavorites = false});

  @override
  State<ResponsiveNavigation> createState() => _ResponsiveNavigationState();
}

class _ResponsiveNavigationState extends State<ResponsiveNavigation> {
  bool _isExpanded = true;

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.showFavorites) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/favorites');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final currentRoute = Get.currentRoute;
    final selectedIndex = _getSelectedIndex(currentRoute);

    if (isLandscape) {
      return _buildSidebar(selectedIndex);
    } else {
      return _buildBottomNavBar(selectedIndex);
    }
  }

  Widget _buildSidebar(int selectedIndex) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: _isExpanded ? 250 : 70,
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Logo e nome do app
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                      _isExpanded
                          ? MainAxisAlignment.spaceBetween
                          : MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isExpanded) ...[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_stories,
                                color: Colors.white,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'LudiTeca',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else
                      const Icon(
                        Icons.auto_stories,
                        color: Colors.white,
                        size: 24,
                      ),

                    if (_isExpanded)
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                        onPressed: _toggleSidebar,
                      )
                    else
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _toggleSidebar,
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Botões de navegação
          _buildNavItem(Icons.explore, 'Explorar', '/home', selectedIndex == 0),
          _buildNavItem(
            Icons.bookmark,
            'Favoritos',
            '/favorites',
            selectedIndex == 2,
          ),
          _buildNavItem(
            Icons.category,
            'Categorias',
            '/library',
            selectedIndex == 1,
          ),
          _buildNavItem(
            Icons.person,
            'Meu Perfil',
            '/profile',
            selectedIndex == 3,
          ),

          const Spacer(),

          // GLOBALTEC Educacional movido para cá
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Text(
                'GLOBALTEC Educacional',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(204),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(int selectedIndex) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                Icons.explore,
                'Explorar',
                '/home',
                selectedIndex == 0,
              ),
              _buildBottomNavItem(
                Icons.bookmark,
                'Favoritos',
                '/favorites',
                selectedIndex == 2,
              ),
              _buildBottomNavItem(
                Icons.category,
                'Categorias',
                '/library',
                selectedIndex == 1,
              ),
              _buildBottomNavItem(
                Icons.person,
                'Meu Perfil',
                '/profile',
                selectedIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    String route,
    bool isSelected,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Get.offAllNamed(route),
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(
            horizontal: _isExpanded ? 16.0 : 8.0,
            vertical: 4.0,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              _isExpanded
                  ? Row(
                    children: [
                      Icon(
                        icon,
                        color:
                            isSelected ? const Color(0xFF2196F3) : Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? const Color(0xFF2196F3)
                                  : Colors.white,
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  )
                  : Center(
                    child: Icon(
                      icon,
                      color:
                          isSelected ? const Color(0xFF2196F3) : Colors.white,
                      size: 24,
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    String route,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => Get.offAllNamed(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF2196F3) : Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF2196F3) : Colors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getSelectedIndex(String route) {
    switch (route) {
      case '/home':
        return 0;
      case '/library':
        return 1;
      case '/favorites':
        return 2;
      case '/profile':
        return 3;
      default:
        return 0;
    }
  }
}
