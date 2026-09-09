import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../state/buffet_provider.dart';
import '../../state/auth_provider.dart';
import 'app_header.dart';

class ResponsiveScaffold extends StatefulWidget {
  final Widget body;
  final int currentIndex;
  final String title;
  final List<Widget>? headerActions;
  final FloatingActionButton? floatingActionButton;

  const ResponsiveScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.title,
    this.headerActions,
    this.floatingActionButton,
  });

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onNavigate(int index) {
    if (index == widget.currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/recepcao');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/kitchen');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/menu');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
      case 5:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 6:
        Navigator.pushReplacementNamed(context, '/demo');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 920;
    final buffet = context.watch<BuffetProvider>();
    final auth = context.watch<AuthProvider>();

    final navItems = [
      const _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Painel Geral',
      ),
      const _NavItem(
        icon: Icons.touch_app_outlined,
        activeIcon: Icons.touch_app,
        label: 'Recepção (Fluxo)',
      ),
      const _NavItem(
        icon: Icons.soup_kitchen_outlined,
        activeIcon: Icons.soup_kitchen,
        label: 'Display Cozinha',
      ),
      const _NavItem(
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book,
        label: 'Cardápio / Alimentos',
      ),
      const _NavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
        label: 'Configurações',
      ),
      const _NavItem(
        icon: Icons.history_outlined,
        activeIcon: Icons.history,
        label: 'Histórico',
      ),
      const _NavItem(
        icon: Icons.play_circle_outline,
        activeIcon: Icons.play_circle_filled,
        label: 'Modo Demo',
      ),
    ];

    if (isDesktop) {
      return Scaffold(
        key: _scaffoldKey,
        body: Column(
          children: [
            AppHeader(
              title: buffet.establishment.name,
              onProfilePressed: () => _onNavigate(4),
              actions: [
                if (buffet.isDemoMode)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, color: Colors.black87, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'MODO DEMO ATIVO',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ...?widget.headerActions,
              ],
            ),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 240,
                    color: VerTheme.sageSidebar,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: VerTheme.primaryGreen.withOpacity(0.08),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.black.withOpacity(0.05),
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                buffet.establishment.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: VerTheme.darkGreen,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Restaurante / Buffet Comercial',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: VerTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: navItems.length,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemBuilder: (context, index) {
                              final item = navItems[index];
                              final isSelected = index == widget.currentIndex;
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? VerTheme.primaryGreen.withOpacity(0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    color: isSelected
                                        ? VerTheme.darkGreen
                                        : VerTheme.textSecondary,
                                    size: 20,
                                  ),
                                  title: Text(
                                    item.label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? VerTheme.darkGreen
                                          : VerTheme.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onTap: () => _onNavigate(index),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: VerTheme.softBackground,
                      child: widget.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: widget.floatingActionButton,
      );
    }

    // Mobile / Tablet Layout
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppHeader(
        title: widget.title,
        onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        onProfilePressed: () => _onNavigate(4),
        actions: widget.headerActions,
      ),
      drawer: Drawer(
        child: Container(
          color: VerTheme.softBackground,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 48,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                color: VerTheme.primaryGreen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.restaurant,
                        color: VerTheme.primaryGreen,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'SmartBuffet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      buffet.establishment.name,
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: navItems.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final item = navItems[index];
                    final isSelected = index == widget.currentIndex;
                    return ListTile(
                      leading: Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected
                            ? VerTheme.primaryGreen
                            : VerTheme.textSecondary,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? VerTheme.primaryGreen
                              : VerTheme.textPrimary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      onTap: () {
                        Navigator.pop(context);
                        _onNavigate(index);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Encerrar Sessão'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: widget.body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: widget.currentIndex > 4 ? 0 : widget.currentIndex,
        selectedItemColor: VerTheme.primaryGreen,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        onTap: (idx) => _onNavigate(idx),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Painel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.touch_app_outlined),
            activeIcon: Icon(Icons.touch_app),
            label: 'Recepção',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.soup_kitchen_outlined),
            activeIcon: Icon(Icons.soup_kitchen),
            label: 'Cozinha',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Cardápio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Config',
          ),
        ],
      ),
      floatingActionButton: widget.floatingActionButton,
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
