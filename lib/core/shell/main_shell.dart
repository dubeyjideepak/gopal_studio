import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/customers')) return 1;
    if (location.startsWith('/reports')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _selectedIndex(context);
    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/bill/new'),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomNav(selectedIndex: idx),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  const _BottomNav({required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: BottomAppBar(
        color: AppColors.surface,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.dashboard_rounded,
              label: 'Home',
              selected: selectedIndex == 0,
              onTap: () => context.go('/dashboard'),
            ),
            _NavItem(
              icon: Icons.people_rounded,
              label: 'Clients',
              selected: selectedIndex == 1,
              onTap: () => context.go('/customers'),
            ),
            const SizedBox(width: 48), // FAB space
            _NavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Reports',
              selected: selectedIndex == 2,
              onTap: () => context.go('/reports'),
            ),
            _NavItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              selected: selectedIndex == 3,
              onTap: () => context.go('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.gold : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.gold : AppColors.textMuted,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
