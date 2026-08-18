import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

/// Persistent shell widget that wraps main tab screens with a bottom navigation bar.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const List<_NavItem> _navItems = [
    _NavItem(label: 'Home',     icon: Icons.dashboard_rounded,       route: AppRoutes.dashboard),
    _NavItem(label: 'Habits',   icon: Icons.self_improvement_rounded, route: AppRoutes.habits),
    _NavItem(label: 'Carbon',   icon: Icons.eco_rounded,              route: AppRoutes.carbon),
    _NavItem(label: 'Insights', icon: Icons.auto_awesome_rounded,     route: AppRoutes.insights),
    _NavItem(label: 'Rewards',  icon: Icons.emoji_events_rounded,     route: AppRoutes.rewards),
  ];

  int _locationToIndex(String location) {
    if (location.startsWith(AppRoutes.habits))   return 1;
    if (location.startsWith(AppRoutes.carbon))   return 2;
    if (location.startsWith(AppRoutes.insights)) return 3;
    if (location.startsWith(AppRoutes.rewards))  return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);
    final theme = Theme.of(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          backgroundColor: theme.colorScheme.surface,
          indicatorColor: AppTheme.primaryGreen.withOpacity(0.15),
          onDestinationSelected: (index) {
            context.go(_navItems[index].route);
          },
          destinations: _navItems.map((item) => NavigationDestination(
            icon: Icon(item.icon, size: 22),
            selectedIcon: Icon(item.icon, size: 22, color: AppTheme.primaryGreen),
            label: item.label,
          )).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon, required this.route});
  final String label;
  final IconData icon;
  final String route;
}
