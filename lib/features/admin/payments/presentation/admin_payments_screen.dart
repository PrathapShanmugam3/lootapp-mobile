import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import '../../../manager/presentation/pay_record_detail_screen.dart';
import '../../presentation/admin_providers.dart';
import 'admin_redeem_codes_screen.dart';

/// Payments section — payment logs / failed payments / pending approvals /
/// redeem codes, as tabs (keeps the admin nav from needing 4 separate
/// top-level destinations for what's really one "money ops" area).
class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: 'Payments',
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [Tab(text: 'Logs'), Tab(text: 'Failed'), Tab(text: 'Pending'), Tab(text: 'Redeem codes')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_LogsTab(), _FailedTab(), _PendingTab(), AdminRedeemCodesScreen()],
      ),
    );
  }
}

class _LogsTab extends ConsumerStatefulWidget {
  const _LogsTab();

  @override
  ConsumerState<_LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends ConsumerState<_LogsTab> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(adminRepositoryProvider).getPaymentLogs();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LoadingState();
        if (snap.hasError) return ErrorState(message: '${snap.error}', onRetry: () => setState(() => _future = ref.read(adminRepositoryProvider).getPaymentLogs()));
        final payments = (snap.data?['payments'] as List?) ?? [];
        if (payments.isEmpty) return const EmptyState(message: 'No payment logs', icon: Icons.receipt_long_outlined);
        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = ref.read(adminRepositoryProvider).getPaymentLogs()),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: payments.length,
            itemBuilder: (context, i) {
              final p = (payments[i] as Map).cast<String, dynamic>();
              final status = p['pay_status']?.toString() ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: statusColor(status).withValues(alpha: 0.12), child: Icon(Icons.payments_outlined, color: statusColor(status), size: 18)),
                  title: Text(p['off_name']?.toString() ?? ''),
                  subtitle: Text('${p['pay_to'] ?? ''} · ₹${p['pay_amount'] ?? 0}'),
                  trailing: StatusChip(text: status, color: statusColor(status)),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _FailedTab extends ConsumerStatefulWidget {
  const _FailedTab();

  @override
  ConsumerState<_FailedTab> createState() => _FailedTabState();
}

class _FailedTabState extends ConsumerState<_FailedTab> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(adminRepositoryProvider).getFailedPayments();
  }

  void _reload() => setState(() => _future = ref.read(adminRepositoryProvider).getFailedPayments());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LoadingState();
        if (snap.hasError) return ErrorState(message: '${snap.error}', onRetry: _reload);
        final payments = (snap.data?['payments'] as List?) ?? [];
        if (payments.isEmpty) return const EmptyState(message: 'No failed payments', icon: Icons.check_circle_outline);
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: payments.length,
            itemBuilder: (context, i) {
              final p = (payments[i] as Map).cast<String, dynamic>();
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.error_outline, color: AppColors.danger),
                  title: Text(p['off_name']?.toString() ?? ''),
                  subtitle: Text('${p['pay_to'] ?? ''} · ₹${p['pay_amount'] ?? 0}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                        builder: (_) => PayRecordDetailScreen(
                          record: p,
                          updatePayRecord: ref.read(adminRepositoryProvider).updatePayRecord,
                          repayPayRecord: ref.read(adminRepositoryProvider).repayPayRecord,
                        ),
                      ))
                      .then((_) => _reload()),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PendingTab extends ConsumerStatefulWidget {
  const _PendingTab();

  @override
  ConsumerState<_PendingTab> createState() => _PendingTabState();
}

class _PendingTabState extends ConsumerState<_PendingTab> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(adminRepositoryProvider).getPendingPayments();
  }

  void _reload() => setState(() => _future = ref.read(adminRepositoryProvider).getPendingPayments());

  Future<void> _resolve(String trxId, bool approve) async {
    try {
      final result = await ref.read(adminRepositoryProvider).resolvePendingPayment(trxId: trxId, approve: approve);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Resolved')));
      _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) return const LoadingState();
        if (snap.hasError) return ErrorState(message: '${snap.error}', onRetry: _reload);
        final payments = (snap.data?['payments'] as List?) ?? [];
        if (payments.isEmpty) return const EmptyState(message: 'No pending payments', icon: Icons.task_alt);
        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: payments.length,
            itemBuilder: (context, i) {
              final p = (payments[i] as Map).cast<String, dynamic>();
              final trxId = p['trx_id']?.toString() ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₹${p['pay_amount'] ?? 0} to ${p['pay_id'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Affiliate: ${p['aff_id'] ?? ''} · Trx: $trxId', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                              onPressed: () => _resolve(trxId, false),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(onPressed: () => _resolve(trxId, true), child: const Text('Approve')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
