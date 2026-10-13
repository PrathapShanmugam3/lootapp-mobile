import 'package:flutter/material.dart';

import '../chat/presentation/chat_screen.dart';
import '../dashboard/presentation/dashboard_screen.dart';
import '../notifications/presentation/notifications_screen.dart';
import '../offers/presentation/offer_detail_screen.dart';
import '../offers/presentation/offers_list_screen.dart';
import '../reports/presentation/reports_screen.dart';
import '../wallet/presentation/wallet_screen.dart';
import 'widgets/affiliate_design.dart';

class AffiliateShell extends StatefulWidget {
  const AffiliateShell({
    super.key,
    this.deepLinkOfferId,
    this.initialTab,
    this.openNotifications = false,
  });

  final String? deepLinkOfferId;

  /// Opens the Notifications list on top (from a tapped wallet/approval push).
  final bool openNotifications;

  /// Tab to open on, by name (`dash`, `offers`, `wallet`, `reports`, `chat`)
  /// — used by `/affiliate?tab=chat` links, e.g. from a tapped push.
  final String? initialTab;

  static const tabNames = ['dash', 'offers', 'wallet', 'reports', 'chat'];

  /// Switches the surrounding shell's bottom tab (e.g. Dashboard's
  /// "View report" → Reports tab). No-op outside the shell.
  static void selectTab(BuildContext context, String name) {
    final i = tabNames.indexOf(name);
    if (i >= 0)
      context.findAncestorStateOfType<_AffiliateShellState>()?._select(i);
  }

  @override
  State<AffiliateShell> createState() => _AffiliateShellState();
}

class _AffiliateShellState extends State<AffiliateShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _tabAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );

  @override
  void dispose() {
    _tabAnim.dispose();
    super.dispose();
  }

  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _tabAnim.forward(from: 0);
  }

  // Must stay in the same order as [AffiliateShell.tabNames] and the nav
  // items below. A static const (not a State field) so a hot reload picks up
  // reordering instead of keeping the old list.
  static const _tabs = [
    DashboardScreen(),
    OffersListScreen(),
    WalletScreen(),
    ReportsScreen(),
    ChatScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final tab = AffiliateShell.tabNames.indexOf(widget.initialTab ?? '');
    if (tab >= 0) _index = tab;
    if (widget.deepLinkOfferId != null || widget.openNotifications) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => widget.deepLinkOfferId != null
                ? OfferDetailScreen(offId: widget.deepLinkOfferId!)
                : const NotificationsScreen(),
          ),
        );
      });
    }
  }

  @override
  void didUpdateWidget(AffiliateShell old) {
    super.didUpdateWidget(old);
    final tab = AffiliateShell.tabNames.indexOf(widget.initialTab ?? '');
    if (widget.initialTab != old.initialTab && tab >= 0) _select(tab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AffColors.pageBg,
      extendBody: true,
      body: AnimatedBuilder(
        animation: _tabAnim,
        builder: (context, child) {
          final t = Curves.easeOutCubic.transform(_tabAnim.value);
          return Opacity(
            opacity: 0.35 + 0.65 * t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 14),
              child: child,
            ),
          );
        },
        child: IndexedStack(index: _index, children: _tabs),
      ),
      bottomNavigationBar: AffNavBar(
        selectedIndex: _index,
        onSelected: _select,
        items: [
          AffNavItem(
            icon: Icons.grid_view_rounded,
            selectedIcon: Icons.grid_view_rounded,
            label: 'Dash',
            from: AffColors.purpleEnd,
            to: AffColors.magenta,
          ),
          AffNavItem(
            icon: Icons.diamond_outlined,
            selectedIcon: Icons.diamond,
            label: 'Campaigns',
            from: Color(0xFFF472B6),
            to: Color(0xFFE11D74),
          ),
          AffNavItem(
            icon: Icons.currency_rupee_rounded,
            selectedIcon: Icons.currency_rupee_rounded,
            label: 'Payouts',
            from: Color(0xFFFBBF24),
            to: Color(0xFFF97316),
          ),
          AffNavItem(
            icon: Icons.insights_outlined,
            selectedIcon: Icons.insights_rounded,
            label: 'Reports',
            from: Color(0xFF34D399),
            to: Color(0xFF059669),
          ),
          AffNavItem(
            icon: Icons.mail_outline_rounded,
            selectedIcon: Icons.mail_rounded,
            label: 'Chat',
            from: Color(0xFF38BDF8),
            to: Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }
}
