import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import 'manager_providers.dart';
import 'pending_payment_resolve_screen.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(managerDashboardProvider);

    return Scaffold(
      appBar: PortalHeader(
        title: 'Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.task_alt_outlined),
            tooltip: 'Resolve pending payment',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PendingPaymentResolveScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(managerDashboardProvider.future),
        child: dashAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: 'Failed to load dashboard.\n$e', onRetry: () => ref.invalidate(managerDashboardProvider)),
          data: (data) {
            final clicks = (data['clicks'] as Map?)?.cast<String, dynamic>() ?? {};
            final conversions = (data['conversions'] as Map?)?.cast<String, dynamic>() ?? {};
            final withdrawals = (data['withdrawals'] as Map?)?.cast<String, dynamic>() ?? {};
            final topOffers = (data['topOffers'] as List?) ?? [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GradientHeroCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Live offers', style: TextStyle(color: Colors.white70)),
                          Text('${data['liveOffers'] ?? 0}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Total users', style: TextStyle(color: Colors.white70)),
                          Text('${data['totalUsers'] ?? 0}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Today'),
                Row(
                  children: [
                    Expanded(child: StatTile(label: 'Clicks today', value: '${clicks['today'] ?? 0}', icon: Icons.ads_click)),
                    const SizedBox(width: 10),
                    Expanded(child: StatTile(label: 'Conversions today', value: '${conversions['today'] ?? 0}', icon: Icons.check_circle_outline)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: StatTile(label: 'Joined today', value: '${data['todayJoinedUsers'] ?? 0}', icon: Icons.person_add_alt)),
                    const SizedBox(width: 10),
                    Expanded(child: StatTile(label: 'Logged in today', value: '${data['todayLoggedUsers'] ?? 0}', icon: Icons.login)),
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
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          child: const Icon(Icons.campaign, color: AppColors.primary, size: 18),
                        ),
                        title: Text(m['offerName']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${m['clicks'] ?? 0} clicks · ${m['conversions'] ?? 0} conversions'),
                        trailing: StatusChip(text: '${m['cr'] ?? 0}% CR'),
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
}
