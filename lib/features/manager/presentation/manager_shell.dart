import 'package:flutter/material.dart';

import '../../../core/widgets/common.dart';

import 'manager_dashboard_screen.dart';
import 'manager_inbox_screen.dart';
import 'manager_offers_screen.dart';
import 'manager_reports_screen.dart';
import 'manager_users_screen.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({super.key});

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _index = 0;

  final _tabs = const [
    ManagerDashboardScreen(),
    ManagerOffersScreen(),
    ManagerReportsScreen(),
    ManagerUsersScreen(),
    ManagerInboxScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: BrandNavBar(
        selectedIndex: _index,
        onSelected: (i) => setState(() => _index = i),
        items: const [
          BrandNavItem(icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Dashboard'),
          BrandNavItem(icon: Icons.local_offer_outlined, selectedIcon: Icons.local_offer, label: 'Offers'),
          BrandNavItem(icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: 'Reports'),
          BrandNavItem(icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Users'),
          BrandNavItem(icon: Icons.inbox_outlined, selectedIcon: Icons.inbox, label: 'Inbox'),
        ],
      ),
    );
  }
}
