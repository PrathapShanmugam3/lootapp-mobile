import 'package:flutter/material.dart';

import '../../../core/widgets/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_providers.dart';
import '../clicks/presentation/admin_clicks_screen.dart';
import '../dashboard/presentation/admin_dashboard_screen.dart';
import '../managers/presentation/admin_managers_screen.dart';
import '../offers/presentation/admin_offers_screen.dart';
import '../payments/presentation/admin_payments_screen.dart';
import '../referrals/presentation/admin_referrals_screen.dart';
import '../settings/presentation/admin_settings_screen.dart';
import '../support/presentation/admin_support_screen.dart';
import '../users/presentation/admin_users_screen.dart';

/// Admin has 7+ sections — too many for a flat bottom nav bar, so the four
/// most-used sections get their own destination and everything else lives
/// behind a "More" tab, a standard native pattern (same idea as iOS/Android
/// apps that outgrow a 5-item tab bar).
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _tabs = const [
    AdminDashboardScreen(),
    AdminOffersScreen(),
    AdminUsersScreen(),
    AdminPaymentsScreen(),
    _MoreScreen(),
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
          BrandNavItem(icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Users'),
          BrandNavItem(icon: Icons.payments_outlined, selectedIcon: Icons.payments, label: 'Payments'),
          BrandNavItem(icon: Icons.more_horiz, selectedIcon: Icons.more_horiz, label: 'More'),
        ],
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  static const _sections = [
    _Section('Managers', Icons.support_agent_outlined, AdminManagersScreen(), AppColors.inkMuted),
    _Section('Referrals', Icons.group_outlined, AdminReferralsScreen(), AppColors.inkMuted),
    _Section('Clicks', Icons.ads_click, AdminClicksScreen(), AppColors.inkMuted),
    _Section('Support inbox', Icons.headset_mic_outlined, AdminSupportScreen(), AppColors.inkMuted),
    _Section('Settings', Icons.settings_outlined, AdminSettingsScreen(), AppColors.inkMuted),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PortalHeader(title: 'More', subtitle: 'Tools & settings', automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          FadeSlideIn(
            child: GradientHeroCard(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LootHat Admin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('Full platform control', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const FadeSlideIn(index: 1, child: SectionHeader(title: 'Sections')),
          FadeSlideIn(
            index: 2,
            child: BentoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < _sections.length; i++) ...[
                    if (i > 0) const RowDivider(),
                    SettingsRow(
                      icon: _sections[i].icon,
                      chipColor: _sections[i].color,
                      label: _sections[i].label,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => _sections[i].screen)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            index: 3,
            child: Consumer(
              builder: (context, ref, _) => BentoCard(
                padding: EdgeInsets.zero,
                child: SettingsRow(
                  icon: Icons.logout_rounded,
                  chipColor: AppColors.danger,
                  label: 'Logout',
                  labelColor: AppColors.danger,
                  trailing: const SizedBox.shrink(),
                  onTap: () => ref.read(authControllerProvider.notifier).logout(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section {
  const _Section(this.label, this.icon, this.screen, this.color);

  final String label;
  final Color color;
  final IconData icon;
  final Widget screen;
}
