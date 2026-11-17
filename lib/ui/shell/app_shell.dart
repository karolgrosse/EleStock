import 'package:flutter/material.dart';

import '../core/widgets/empty_state.dart';
import '../inventory/inventory_screen.dart';
import '../profile/profile_screen.dart';
import '../scanner/scanner_screen.dart';

/// The top-level sections of the app.
///
/// A bottom [NavigationBar] on phones, a [NavigationRail] on wide windows
/// (the workshop tablet). Each section keeps its state (search text, scroll
/// position) when you switch away and back.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// Material 3 "expanded" window class, the same as the inventory's
  /// master–detail breakpoint.
  static const wideBreakpoint = 840.0;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _Section {
  const _Section(this.label, this.icon, this.selectedIcon, this.build);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder build;
}

final _sections = <_Section>[
  _Section(
    'Inventory',
    Icons.inventory_2_outlined,
    Icons.inventory_2,
    (_) => const InventoryScreen(),
  ),
  _Section(
    'Scan',
    Icons.qr_code_scanner_outlined,
    Icons.qr_code_scanner,
    (_) => const ScannerScreen(),
  ),
  _Section(
    'History',
    Icons.history_outlined,
    Icons.history,
    (_) => const _ComingSoonSection(title: 'History', icon: Icons.history),
  ),
  _Section(
    'Shopping',
    Icons.shopping_cart_outlined,
    Icons.shopping_cart,
    (_) => const _ComingSoonSection(
      title: 'Shopping list',
      icon: Icons.shopping_cart_outlined,
    ),
  ),
  _Section(
    'Profile',
    Icons.person_outline,
    Icons.person,
    (_) => const ProfileScreen(),
  ),
];

class _AppShellState extends State<AppShell> {
  int _index = 0;

  /// Sections are built the first time they are opened, then kept alive.
  final _visited = <int>{0};

  void _select(int index) => setState(() {
    _index = index;
    _visited.add(index);
  });

  @override
  Widget build(BuildContext context) {
    final body = IndexedStack(
      index: _index,
      children: [
        for (var i = 0; i < _sections.length; i++)
          _visited.contains(i)
              ? _sections[i].build(context)
              : const SizedBox.shrink(),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppShell.wideBreakpoint) {
          return Scaffold(
            body: body,
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: [
                for (final s in _sections)
                  NavigationDestination(
                    icon: Icon(s.icon),
                    selectedIcon: Icon(s.selectedIcon),
                    label: s.label,
                  ),
              ],
            ),
          );
        }
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: _select,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final s in _sections)
                      NavigationRailDestination(
                        icon: Icon(s.icon),
                        selectedIcon: Icon(s.selectedIcon),
                        label: Text(s.label),
                      ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}

/// Placeholder for sections whose screens are not merged yet.
class _ComingSoonSection extends StatelessWidget {
  const _ComingSoonSection({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(icon: icon, message: '$title is coming soon'),
    );
  }
}
