import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/chat_message.dart';
import '../chat/presentation/chat_providers.dart';
import '../notifications/domain/notification.dart';
import '../wallet/domain/wallet_models.dart';

/// Offline fallback content, shown (always with a "Sample data" banner) when
/// the server can't be reached, so screens never sit on a bare error.
/// Deliberately generic — no real brands, links or identities.
class SampleData {
  SampleData._();

  static final Map<String, dynamic> dashboard = {
    'user': {'name': 'Affiliate'},
    'liveOffers': 12,
    'kpis': {
      'clicks': {'value': 842, 'trend': 8.2, 'direction': 'up'},
      'conversions': {'value': 54, 'mtd': 231},
      'earnings': {'value': 12450},
    },
    'chart': [for (final v in [900, 1500, 1200, 2400, 2100, 3000, 2700]) {'earnings': v}],
    'topCampaigns': [
      {'name': 'Demat Account', 'earnings': 4200, 'conversions': 21, 'maxEarnings': 6000},
      {'name': 'UPI Wallet Signup', 'earnings': 3100, 'conversions': 17, 'maxEarnings': 6000},
      {'name': 'Credit Card Offer', 'earnings': 1900, 'conversions': 9, 'maxEarnings': 6000},
    ],
  };

  static final Map<String, dynamic> profile = {
    'name': 'Sample Affiliate',
    'email': 'sample@example.com',
    'mobile': '9000000000',
    'balance': 0,
    'refLinks': 0,
    'userId': '—',
  };

  static final List<Map<String, dynamic>> offers = [
    {'off_id': 'sample-1', 'offer_name': 'Demat Account', 'offer_title': 'Open a free account', 'category': 'Demat', 'payout': 450},
    {'off_id': 'sample-2', 'offer_name': 'UPI Wallet Signup', 'offer_title': 'Sign up and verify', 'category': 'Payments', 'payout': 120},
    {'off_id': 'sample-3', 'offer_name': 'Credit Card Offer', 'offer_title': 'Apply and get approved', 'category': 'Cards', 'payout': 800},
  ];

  static const walletSummary = WalletSummary(balance: 4820, totalEarned: 18450, totalWithdrawn: 13630);

  static const transactions = [
    WalletTransaction(id: -1, type: 'credit', amount: 450, comment: 'Offer conversion', status: 'success', date: 'Today', time: '11:20'),
    WalletTransaction(id: -2, type: 'debit', amount: 1000, comment: 'Withdrawal', status: 'pending', date: 'Yesterday', time: '09:10'),
    WalletTransaction(id: -3, type: 'credit', amount: 120, comment: 'Offer conversion', status: 'success', date: 'Yesterday', time: '08:42'),
  ];

  static const chat = ChatState(status: 'open', messages: [
    ChatMessageModel(id: -1, from: 'admin', text: 'Hi! How can we help you today?', time: '10:00'),
  ]);

  static const notifications = [
    AppNotification(id: -1, title: 'Welcome to LootHat', message: 'Browse campaigns and start earning.', isRead: false, createdAt: 'Today'),
    AppNotification(id: -2, title: 'New offers added', message: 'Fresh campaigns are live in the directory.', isRead: true, createdAt: 'Yesterday'),
  ];

  static final Map<String, dynamic> reports = {
    'current': {'totalClicks': 842, 'totalConversions': 54, 'totalEarnings': 12450},
    'previous': {'totalClicks': 760, 'totalConversions': 48, 'totalEarnings': 10900},
    'campaigns': [
      {'offId': 'sample-1', 'offerName': 'Demat Account', 'totalClicks': 410, 'totalLeads': 28, 'totalEarnings': 6200},
      {'offId': 'sample-2', 'offerName': 'UPI Wallet Signup', 'totalClicks': 260, 'totalLeads': 19, 'totalEarnings': 3600},
    ],
  };

  static final Map<String, dynamic> detailedReport = {
    'stats': {'totalClicks': 410, 'totalConversions': 28, 'totalEarnings': 6200},
    'rows': [
      {'clickId': 'SAMPLE-0001', 'status': 'Converted', 'userIdentity': {'label': 'User', 'value': '90••••00'}, 'date': 'Today', 'time': '10:11'},
      {'clickId': 'SAMPLE-0002', 'status': 'Pending', 'userIdentity': {'label': 'User', 'value': '91••••12'}, 'date': 'Today', 'time': '10:30'},
    ],
  };
}

/// True when [v] failed with no earlier data — the cue to show sample data.
bool isSample(AsyncValue<Object?> v) => v.hasError && !v.hasValue;

/// Swaps a failed [v] for [sample]; loading and real data pass through.
AsyncValue<T> withSample<T>(AsyncValue<T> v, T sample) => isSample(v) ? AsyncData(sample) : v;
