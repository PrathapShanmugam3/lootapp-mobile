import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/admin_providers.dart';

/// Settings hub — a list of secondary admin sections (gateways, IP
/// allowlist, account-delete requests) that don't need their own nav
/// destination. Each opens a simple list screen.
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PortalHeader(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _tile(context, Icons.dns_outlined, 'Payment gateways', const AdminGatewaysScreen()),
          _tile(context, Icons.shield_outlined, 'IP allowlist', const AdminIpAllowlistScreen()),
          _tile(context, Icons.person_remove_outlined, 'Account delete requests', const AdminAccountDeleteScreen()),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, Widget screen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.12), child: Icon(icon, color: AppColors.primary, size: 18)),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}

class AdminGatewaysScreen extends ConsumerWidget {
  const AdminGatewaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: PortalHeader(title: 'Payment gateways'),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.read(adminRepositoryProvider).getGatewaysFull(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingState();
          if (snap.hasError) return ErrorState(message: '${snap.error}');
          final gateways = snap.data ?? [];
          if (gateways.isEmpty) return const EmptyState(message: 'No gateways configured', icon: Icons.dns_outlined);
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: gateways.length,
            itemBuilder: (context, i) {
              final g = gateways[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.dns_outlined, color: AppColors.primary),
                  title: Text(g['gname']?.toString() ?? ''),
                  subtitle: Text('Type: ${g['gtype'] ?? ''}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminIpAllowlistScreen extends ConsumerWidget {
  const AdminIpAllowlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: PortalHeader(title: 'IP allowlist'),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.read(adminRepositoryProvider).getWhitelistedIps(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingState();
          if (snap.hasError) return ErrorState(message: '${snap.error}');
          final ips = snap.data ?? [];
          if (ips.isEmpty) return const EmptyState(message: 'No IPs allowlisted', icon: Icons.shield_outlined);
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: ips.length,
            itemBuilder: (context, i) {
              final ip = ips[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.shield_outlined, color: AppColors.primary),
                  title: Text(ip['ip']?.toString() ?? ''),
                  subtitle: Text(ip['label']?.toString() ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminAccountDeleteScreen extends ConsumerStatefulWidget {
  const AdminAccountDeleteScreen({super.key});

  @override
  ConsumerState<AdminAccountDeleteScreen> createState() => _AdminAccountDeleteScreenState();
}

class _AdminAccountDeleteScreenState extends ConsumerState<AdminAccountDeleteScreen> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(adminRepositoryProvider).getAccountDeleteRequests();
  }

  void _reload() => setState(() => _future = ref.read(adminRepositoryProvider).getAccountDeleteRequests());

  Future<void> _updateStatus(dynamic id, String status) async {
    try {
      await ref.read(adminRepositoryProvider).updateAccountDeleteRequestStatus(id, status);
      _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PortalHeader(title: 'Account delete requests'),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingState();
          if (snap.hasError) return ErrorState(message: '${snap.error}', onRetry: _reload);
          final requests = (snap.data?['requests'] as List?) ?? [];
          if (requests.isEmpty) return const EmptyState(message: 'No pending requests', icon: Icons.person_remove_outlined);
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: requests.length,
              itemBuilder: (context, i) {
                final r = (requests[i] as Map).cast<String, dynamic>();
                final status = r['status']?.toString() ?? 'pending';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(r['email']?.toString() ?? ''),
                    subtitle: Text('Status: $status'),
                    trailing: status == 'pending'
                        ? PopupMenuButton<String>(
                            onSelected: (v) => _updateStatus(r['id'], v),
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'approved', child: Text('Approve')),
                              PopupMenuItem(value: 'rejected', child: Text('Reject')),
                            ],
                          )
                        : StatusChip(text: status, color: statusColor(status)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
