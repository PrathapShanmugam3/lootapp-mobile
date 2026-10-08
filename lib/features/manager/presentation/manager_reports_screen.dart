import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import 'manager_providers.dart';
import 'pay_record_detail_screen.dart';

/// Reports tab — referrals / clicks / payment logs, presented as expandable
/// cards (not literal web tables) with a search bar and pull-to-refresh.
class ManagerReportsScreen extends StatefulWidget {
  const ManagerReportsScreen({super.key});

  @override
  State<ManagerReportsScreen> createState() => _ManagerReportsScreenState();
}

class _ManagerReportsScreenState extends State<ManagerReportsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PortalHeader(
        title: 'Reports',
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Referrals'), Tab(text: 'Clicks'), Tab(text: 'Payments')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ReferralsTab(), _ClicksTab(), _PaymentsTab()],
      ),
    );
  }
}

class _ReferralsTab extends ConsumerStatefulWidget {
  const _ReferralsTab();

  @override
  ConsumerState<_ReferralsTab> createState() => _ReferralsTabState();
}

class _ReferralsTabState extends ConsumerState<_ReferralsTab> {
  final _searchCtrl = TextEditingController();
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = ref.read(managerRepositoryProvider).getReferrals(search: _searchCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search referrals…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: () => setState(_load)),
            ),
            onSubmitted: (_) => setState(_load),
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) return const LoadingState();
              if (snap.hasError) return ErrorState(message: '${snap.error}', onRetry: () => setState(_load));
              final referrals = (snap.data?['referrals'] as List?) ?? [];
              if (referrals.isEmpty) return const EmptyState(message: 'No referrals found', icon: Icons.group_outlined);
              return RefreshIndicator(
                onRefresh: () async => setState(_load),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: referrals.length,
                  itemBuilder: (context, i) {
                    final r = (referrals[i] as Map).cast<String, dynamic>();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        title: Text(r['offer_name']?.toString() ?? r['offer_id']?.toString() ?? ''),
                        subtitle: Text('Affiliate: ${r['aff_id'] ?? ''}'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: _KeyValueGrid(map: r),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ClicksTab extends ConsumerStatefulWidget {
  const _ClicksTab();

  @override
  ConsumerState<_ClicksTab> createState() => _ClicksTabState();
}

class _ClicksTabState extends ConsumerState<_ClicksTab> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(managerRepositoryProvider).getClicks();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LoadingState();
        if (snap.hasError) return ErrorState(message: '${snap.error}', onRetry: () => setState(() => _future = ref.read(managerRepositoryProvider).getClicks()));
        final clicks = (snap.data?['clicks'] as List?) ?? [];
        if (clicks.isEmpty) return const EmptyState(message: 'No clicks recorded yet', icon: Icons.ads_click);
        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = ref.read(managerRepositoryProvider).getClicks()),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: clicks.length,
            itemBuilder: (context, i) {
              final c = (clicks[i] as Map).cast<String, dynamic>();
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.ads_click, color: AppColors.primary),
                  title: Text(c['off_name']?.toString() ?? c['off_id']?.toString() ?? ''),
                  subtitle: Text('Affiliate: ${c['aff_id'] ?? ''} · ${c['date'] ?? ''} ${c['time'] ?? ''}'),
                  trailing: StatusChip(text: c['click_status'] == '1' ? 'Converted' : 'Pending', color: statusColor(c['click_status'] == '1' ? 'success' : 'pending')),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PaymentsTab extends ConsumerStatefulWidget {
  const _PaymentsTab();

  @override
  ConsumerState<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends ConsumerState<_PaymentsTab> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(managerRepositoryProvider).getPaymentLogs();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LoadingState();
        if (snap.hasError) return ErrorState(message: '${snap.error}', onRetry: () => setState(() => _future = ref.read(managerRepositoryProvider).getPaymentLogs()));
        final payments = (snap.data?['payments'] as List?) ?? [];
        if (payments.isEmpty) return const EmptyState(message: 'No payment logs found', icon: Icons.receipt_long_outlined);
        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = ref.read(managerRepositoryProvider).getPaymentLogs()),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: payments.length,
            itemBuilder: (context, i) {
              final p = (payments[i] as Map).cast<String, dynamic>();
              final status = p['pay_status']?.toString() ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor(status).withValues(alpha: 0.12),
                    child: Icon(Icons.payments_outlined, color: statusColor(status), size: 18),
                  ),
                  title: Text(p['off_name']?.toString() ?? ''),
                  subtitle: Text('${p['pay_to'] ?? ''} · ₹${p['pay_amount'] ?? 0}'),
                  trailing: StatusChip(text: status, color: statusColor(status)),
                  onTap: status.toLowerCase() == 'failed'
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PayRecordDetailScreen(record: p)),
                          )
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _KeyValueGrid extends StatelessWidget {
  const _KeyValueGrid({required this.map});

  final Map<String, dynamic> map;

  @override
  Widget build(BuildContext context) {
    final entries = map.entries.where((e) => e.value != null && e.value.toString().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries
          .map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 110, child: Text(e.key, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
                    Expanded(child: Text(e.value.toString(), style: const TextStyle(fontSize: 11.5))),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
