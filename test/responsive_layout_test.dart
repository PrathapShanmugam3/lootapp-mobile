import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loothat_app/core/theme/app_theme.dart';
import 'package:loothat_app/core/widgets/chat_message.dart';
import 'package:loothat_app/features/affiliate/chat/presentation/chat_providers.dart';
import 'package:loothat_app/features/affiliate/chat/presentation/chat_screen.dart';
import 'package:loothat_app/features/affiliate/dashboard/presentation/dashboard_providers.dart';
import 'package:loothat_app/features/affiliate/dashboard/presentation/dashboard_screen.dart';
import 'package:loothat_app/features/affiliate/offers/presentation/offers_list_screen.dart';
import 'package:loothat_app/features/affiliate/offers/presentation/offers_providers.dart';
import 'package:loothat_app/features/affiliate/profile/presentation/profile_providers.dart';
import 'package:loothat_app/features/affiliate/profile/presentation/profile_screen.dart';
import 'package:loothat_app/features/affiliate/reports/presentation/reports_providers.dart';
import 'package:loothat_app/features/affiliate/reports/presentation/reports_screen.dart';
import 'package:loothat_app/features/affiliate/wallet/domain/wallet_models.dart';
import 'package:loothat_app/features/affiliate/wallet/presentation/wallet_providers.dart';
import 'package:loothat_app/features/affiliate/wallet/presentation/wallet_screen.dart';
import 'package:loothat_app/features/auth/presentation/login_screen.dart';
import 'package:loothat_app/features/legal/presentation/terms_screen.dart';
import 'package:loothat_app/features/legal/presentation/privacy_policy_screen.dart';
import 'package:loothat_app/features/legal/presentation/account_delete_screen.dart';
import 'package:loothat_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:loothat_app/features/affiliate/custom_domains/presentation/custom_domains_providers.dart';
import 'package:loothat_app/features/affiliate/custom_domains/presentation/custom_domains_screen.dart';
import 'package:loothat_app/features/affiliate/notifications/domain/notification.dart';
import 'package:loothat_app/features/affiliate/notifications/presentation/notifications_providers.dart';
import 'package:loothat_app/features/affiliate/notifications/presentation/notifications_screen.dart';
import 'package:loothat_app/features/affiliate/offers/presentation/offer_detail_screen.dart';
import 'package:loothat_app/features/affiliate/profile/presentation/edit_account_screen.dart';
import 'package:loothat_app/features/affiliate/redeem/presentation/redeem_screen.dart';
import 'package:loothat_app/features/affiliate/reports/presentation/detailed_report_screen.dart';
import 'package:loothat_app/features/affiliate/presentation/widgets/affiliate_design.dart';

class _FakeChat extends ChatNotifier {
  @override
  Future<ChatState> build() async => ChatState(status: 'open', messages: [
        for (var i = 0; i < 12; i++)
          ChatMessageModel(id: i, from: i.isEven ? 'user' : 'admin', text: 'A fairly long message to check wrapping on narrow screens $i', time: '10:0$i', date: 'Today'),
      ]);
  @override
  Future<void> poll() async {}
}

class _FakeTxns extends TransactionsNotifier {
  @override
  Future<List<WalletTransaction>> build() async => [
        for (var i = 0; i < 5; i++)
          WalletTransaction(id: i, type: i.isEven ? 'credit' : 'debit', amount: 1234.5, comment: 'A long transaction comment that must ellipsize', status: 'success', date: '08 Oct', time: '11:20'),
      ];
}

const _sizes = <String, Size>{
  'tiny 320x568': Size(320, 568),
  'small 360x640': Size(360, 640),
  'normal 390x844': Size(390, 844),
  'large 430x932': Size(430, 932),
  'tablet 820x1180': Size(820, 1180),
};

Future<void> _loadFont(String family, String asset) async {
  final loader = FontLoader(family)..addFont(rootBundle.load(asset));
  await loader.load();
}

void main() {
  // Real fonts: flutter_test otherwise draws every glyph with the blocky
  // "Ahem" font, which is far wider than real text and fakes overflows.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFont('PlusJakartaSans', 'assets/fonts/PlusJakartaSans.ttf');
    await _loadFont('SpaceGrotesk', 'assets/fonts/SpaceGrotesk.ttf');
  });

  final overrides = [
    chatProvider.overrideWith(_FakeChat.new),
    transactionsProvider.overrideWith(_FakeTxns.new),
    walletSummaryProvider.overrideWith((ref) async => const WalletSummary(balance: 1234567.5, totalEarned: 9876543, totalWithdrawn: 123456)),
    dashboardProvider.overrideWith((ref) async => {
          'user': {'name': 'A Very Long Affiliate Name Indeed'},
          'liveOffers': 24,
          'kpis': {
            'clicks': {'value': 1284000, 'trend': 12.4, 'direction': 'up'},
            'conversions': {'value': 86000, 'mtd': 412},
            'earnings': {'value': 1845000},
          },
          'chart': [for (final v in [1200, 2100, 1700, 3200, 2800, 4100, 3600]) {'earnings': v, 'conversions': v ~/ 100}],
          'topCampaigns': [
            {'name': 'A really long campaign name that should ellipsize nicely', 'earnings': 6200, 'conversions': 31},
          ],
        }),
    offersListProvider.overrideWith((ref) async => [
          {'off_id': '1', 'offer_name': 'A really long campaign name that should ellipsize nicely', 'offer_title': 'Open a free account today', 'category': 'Demat', 'payout': 450},
          {'off_id': '2', 'offer_name': 'Short', 'category': 'Payments', 'payout': 120},
        ]),
    reportsProvider.overrideWith((ref, f) async => {
          'current': {'totalClicks': 1284, 'totalConversions': 86, 'totalEarnings': 18450},
          'previous': {'totalClicks': 1000, 'totalConversions': 70, 'totalEarnings': 15000},
          'campaigns': [
            {'offId': '1', 'offerName': 'A really long campaign name that should ellipsize nicely', 'totalClicks': 600, 'totalLeads': 41, 'totalEarnings': 9200},
          ],
        }),
    notificationsProvider.overrideWith((ref) async => const [
          AppNotification(id: 1, title: 'A rather long notification title that wraps', message: 'A long message body that should wrap across several lines on a narrow device.', isRead: false, createdAt: '08 Oct'),
        ]),
    customDomainsProvider.overrideWith((ref) async => [
          {'id': 1, 'domain': 'a-very-long-subdomain.links.example-domain.com', 'verified': true},
        ]),
    offerDetailProvider.overrideWith((ref, id) async => {
          'offer': {'offerName': 'A really long campaign name that should ellipsize nicely', 'category': 'Demat', 'offerTitle': 'Open a free demat account in minutes', 'totalPayout': 450, 'events': [], 'steps': '1. Share\n2. Earn'},
          'referralLink': {'offerLink': 'https://example.com/o/a-very-long-link-that-must-not-overflow-abc123', 'referLink': 'https://example.com/r/xyz', 'landingTheme': 'classic'},
        }),
    detailedReportProvider.overrideWith((ref, f) async => {
          'stats': {'totalClicks': 600, 'totalConversions': 41, 'totalEarnings': 9200},
          'rows': [
            {'clickId': 'CLK-93821-A-VERY-LONG-CLICK-IDENTIFIER', 'status': 'Converted', 'userIdentity': {'label': 'User', 'value': '98••••21'}, 'date': '08 Oct', 'time': '10:11'},
          ],
        }),
    profileProvider.overrideWith((ref) async => {
          'name': 'A Very Long Affiliate Name Indeed',
          'email': 'a.very.long.email.address@example-domain.com',
          'mobile': '9876543210',
          'balance': 4820,
          'refLinks': 12,
          'tier': 'Gold',
          'userId': 10482,
          'upi': 'name@upi',
        }),
  ];

  final screens = <String, Widget Function()>{
    'Login': () => const LoginScreen(),
    'Terms': () => const TermsScreen(),
    'Dashboard': () => const DashboardScreen(),
    'Campaigns': () => const OffersListScreen(),
    'Payouts': () => const WalletScreen(),
    'Reports': () => const ReportsScreen(),
    'Chat': () => const ChatScreen(),
    'Profile': () => const ProfileScreen(),
    'Privacy': () => const PrivacyPolicyScreen(),
    'Delete account': () => const AccountDeleteScreen(),
    'Forgot password': () => const ForgotPasswordScreen(),
    'Notifications': () => const NotificationsScreen(),
    'Custom domains': () => const CustomDomainsScreen(),
    'Redeem': () => const RedeemScreen(),
    'Offer detail': () => const OfferDetailScreen(offId: '1'),
    'Click report': () => const DetailedReportScreen(offId: '1', offerName: 'A really long campaign name that should ellipsize nicely'),
    'Edit account': () => const EditAccountScreen(profile: {'name': 'A Very Long Affiliate Name Indeed', 'email': 'a.very.long.email.address@example-domain.com', 'mobile': '9876543210', 'upi': 'name@upi'}),
  };

  // The reCAPTCHA WebView has no platform implementation under flutter_test.
  bool isWebViewTestGap(Object? e) => e.toString().contains('webview_flutter');

  for (final size in _sizes.entries) {
    for (final screen in screens.entries) {
      testWidgets('${screen.key} fits ${size.key} without overflow', (tester) async {
        tester.view.physicalSize = size.value * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(ProviderScope(
          overrides: overrides,
          child: MaterialApp(
            theme: AppTheme.current(),
            home: Scaffold(
              extendBody: true,
              body: screen.value(),
              bottomNavigationBar: !{'Dashboard', 'Campaigns', 'Payouts', 'Reports', 'Chat', 'Profile'}.contains(screen.key)
                  ? null
                  : AffNavBar(selectedIndex: 0, onSelected: (_) {}, items: const [
                      AffNavItem(icon: Icons.grid_view_rounded, selectedIcon: Icons.grid_view_rounded, label: 'Dash'),
                      AffNavItem(icon: Icons.diamond_outlined, selectedIcon: Icons.diamond, label: 'Campaigns'),
                      AffNavItem(icon: Icons.currency_rupee_rounded, selectedIcon: Icons.currency_rupee_rounded, label: 'Payouts'),
                      AffNavItem(icon: Icons.insights_outlined, selectedIcon: Icons.insights_rounded, label: 'Reports'),
                      AffNavItem(icon: Icons.mail_outline_rounded, selectedIcon: Icons.mail_rounded, label: 'Chat'),
                    ]),
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        final e = tester.takeException();
        expect(e == null || isWebViewTestGap(e), isTrue, reason: '$e');
      });
    }
  }
}
