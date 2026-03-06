import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/controllers/auth_controller.dart';

// Enum para identificar a página atual
enum ActivePage { home, library, categories, profile, favorites }

class RetractableSidebar extends StatefulWidget {
  final ActivePage activePage;

  const RetractableSidebar({super.key, required this.activePage});

  @override
  State<RetractableSidebar> createState() => _RetractableSidebarState();
}

class _RetractableSidebarState extends State<RetractableSidebar> {
  bool _isExpanded = true;

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isExpanded ? 240 : 60,
      color: Colors.blue.shade900,
      child: Column(
        children: [
          // Logo e botão para expandir/recolher
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment:
                  _isExpanded
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.center,
              children: [
                if (_isExpanded)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: const Text(
                        'LudiTeca',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  const Icon(Icons.menu_book, size: 30, color: Colors.white),

                // Ícone para expandir/recolher
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.chevron_left : Icons.chevron_right,
                    color: Colors.white,
                  ),
                  onPressed: _toggleSidebar,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Botões de navegação
          _buildNavButton(
            icon: Icons.home,
            label: 'Início',
            isActive: widget.activePage == ActivePage.home,
            onTap: () => Navigator.pushNamed(context, '/home'),
          ),

          _buildNavButton(
            icon: Icons.book,
            label: 'Biblioteca',
            isActive: widget.activePage == ActivePage.library,
            onTap: () => Navigator.pushNamed(context, '/library'),
          ),

          _buildNavButton(
            icon: Icons.category,
            label: 'Categorias',
            isActive: widget.activePage == ActivePage.categories,
            onTap: () => Navigator.pushNamed(context, '/categories'),
          ),

          _buildNavButton(
            icon: Icons.favorite,
            label: 'Favoritos',
            isActive: widget.activePage == ActivePage.favorites,
            onTap: () => Navigator.pushNamed(context, '/favorites'),
          ),

          _buildNavButton(
            icon: Icons.person,
            label: 'Perfil',
            isActive: widget.activePage == ActivePage.profile,
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),

          const Spacer(),

          // Botão de sair
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildNavButton(
              icon: Icons.exit_to_app,
              label: 'Sair',
              isActive: false,
              onTap: () async {
                final authController = Provider.of<AuthController>(
                  context,
                  listen: false,
                );
                final success = await authController.signOut();
                if (success && context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: _isExpanded ? 16.0 : 8.0,
          ),
          child:
              _isExpanded
                  ? Row(
                    children: [
                      Icon(
                        icon,
                        color:
                            isActive
                                ? Colors.white
                                : Colors.white.withAlpha(76),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color:
                                isActive
                                    ? Colors.white
                                    : Colors.white.withAlpha(76),
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                  : Center(
                    child: Icon(
                      icon,
                      color:
                          isActive ? Colors.white : Colors.white.withAlpha(76),
                      size: 24,
                    ),
                  ),
        ),
      ),
    );
  }
}
