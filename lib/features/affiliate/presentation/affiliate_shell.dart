import 'package:flutter/material.dart';

import '../chat/presentation/chat_screen.dart';
import '../dashboard/presentation/dashboard_screen.dart';
import '../offers/presentation/offer_detail_screen.dart';
import '../offers/presentation/offers_list_screen.dart';
import '../profile/presentation/profile_screen.dart';
import '../wallet/presentation/wallet_screen.dart';
import 'widgets/affiliate_design.dart';

class AffiliateShell extends StatefulWidget {
  const AffiliateShell({super.key, this.deepLinkOfferId});

  final String? deepLinkOfferId;

  @override
  State<AffiliateShell> createState() => _AffiliateShellState();
}

class _AffiliateShellState extends State<AffiliateShell> with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _tabAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 320), value: 1);

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

  final _tabs = const [
    DashboardScreen(),
    OffersListScreen(),
    WalletScreen(),
    ChatScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.deepLinkOfferId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OfferDetailScreen(offId: widget.deepLinkOfferId!)),
        );
      });
    }
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
          return Opacity(opacity: 0.35 + 0.65 * t, child: Transform.translate(offset: Offset(0, (1 - t) * 14), child: child));
        },
        child: IndexedStack(index: _index, children: _tabs),
      ),
      bottomNavigationBar: AffNavBar(
        selectedIndex: _index,
        onSelected: _select,
        items: const [
          AffNavItem(icon: Icons.grid_view_rounded, selectedIcon: Icons.grid_view_rounded, label: 'Dash', color: AffColors.purpleEnd),
          AffNavItem(icon: Icons.diamond_outlined, selectedIcon: Icons.diamond, label: 'Campaigns', color: AffColors.pink),
          AffNavItem(icon: Icons.currency_rupee_rounded, selectedIcon: Icons.currency_rupee_rounded, label: 'Payouts', color: AffColors.orange),
          AffNavItem(icon: Icons.mail_outline_rounded, selectedIcon: Icons.mail_rounded, label: 'Chat', color: AffColors.cyan),
          AffNavItem(icon: Icons.sentiment_satisfied_alt_rounded, selectedIcon: Icons.sentiment_satisfied_alt_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}
