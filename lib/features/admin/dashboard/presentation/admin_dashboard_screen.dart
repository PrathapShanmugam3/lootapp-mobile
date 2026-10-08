import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/admin_providers.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(adminDashboardProvider);

    return Scaffold(
      appBar: PortalHeader(
        title: 'Admin dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Reconcile payments',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final result = await ref.read(adminRepositoryProvider).reconcilePayments();
                messenger.showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Reconciliation triggered')));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(adminDashboardProvider.future),
        child: dashAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: 'Failed to load dashboard.\n$e', onRetry: () => ref.invalidate(adminDashboardProvider)),
          data: (data) {
            final clicks = (data['clicks'] as Map?)?.cast<String, dynamic>() ?? {};
            final conversions = (data['conversions'] as Map?)?.cast<String, dynamic>() ?? {};
            final withdrawals = (data['withdrawals'] as Map?)?.cast<String, dynamic>() ?? {};
            final failedPayouts = (data['failedPayouts'] as Map?)?.cast<String, dynamic>() ?? {};
            final topOffers = (data['topOffers'] as List?) ?? [];
            final recentPayments = (data['recentPayments'] as List?) ?? [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GradientHeroCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total wallet balance', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text(_currency.format(data['totalWalletBalance'] ?? 0), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _heroStat('Processing', _currency.format(data['processingAmount'] ?? 0)),
                          _heroStat('Pending', _currency.format(data['pendingAmount'] ?? 0)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Overview'),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.5,
                  children: [
                    StatTile(label: 'Live offers', value: '${data['liveOffers'] ?? 0}', icon: Icons.local_offer_outlined),
                    StatTile(label: 'Total users', value: '${data['totalUsers'] ?? 0}', icon: Icons.people_outline),
                    StatTile(label: 'Clicks today', value: '${clicks['today'] ?? 0}', icon: Icons.ads_click),
                    StatTile(label: 'Conversions today', value: '${conversions['today'] ?? 0}', icon: Icons.check_circle_outline),
                  ],
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Withdrawals'),
                Row(
                  children: [
                    Expanded(child: StatTile(label: 'Today', value: _currency.format(withdrawals['today'] ?? 0))),
                    const SizedBox(width: 10),
                    Expanded(child: StatTile(label: 'This month', value: _currency.format(withdrawals['month'] ?? 0))),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                        const SizedBox(width: 10),
                        Expanded(child: Text('Failed payouts today: ${_currency.format(failedPayouts['today'] ?? 0)}')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Top offers (by conversion rate)'),
                if (topOffers.isEmpty)
                  const EmptyState(message: 'No offer activity yet', icon: Icons.campaign_outlined)
                else
                  ...topOffers.map((o) {
                    final m = (o as Map).cast<String, dynamic>();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.12), child: const Icon(Icons.campaign, color: AppColors.primary, size: 18)),
                        title: Text(m['offerName']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${m['clicks'] ?? 0} clicks · ${m['conversions'] ?? 0} conversions'),
                        trailing: StatusChip(text: '${m['cr'] ?? 0}% CR'),
                      ),
                    );
                  }),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Recent payments'),
                if (recentPayments.isEmpty)
                  const EmptyState(message: 'No recent payments', icon: Icons.receipt_long_outlined)
                else
                  ...recentPayments.take(10).map((p) {
                    final m = (p as Map).cast<String, dynamic>();
                    final status = m['status']?.toString() ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(m['offName']?.toString() ?? ''),
                        subtitle: Text('${m['date'] ?? ''} ${m['time'] ?? ''}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(_currency.format(m['amount'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            StatusChip(text: status, color: statusColor(status)),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ],
    );
  }
}
