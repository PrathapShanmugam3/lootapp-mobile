import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/admin_providers.dart';

String _formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  return '${h}h ${m}m';
}

class AdminManagersScreen extends ConsumerWidget {
  const AdminManagersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managersAsync = ref.watch(adminManagersActivityProvider);

    return Scaffold(
      appBar: PortalHeader(title: 'Managers'),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(adminManagersActivityProvider.future),
        child: managersAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: 'Failed to load managers.\n$e', onRetry: () => ref.invalidate(adminManagersActivityProvider)),
          data: (managers) {
            if (managers.isEmpty) return const EmptyState(message: 'No managers found', icon: Icons.support_agent_outlined);
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: managers.length,
              itemBuilder: (context, i) {
                final m = managers[i];
                final online = m['isOnline'] == true;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Stack(
                      children: [
                        const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.support_agent, color: Colors.white, size: 18)),
                        if (online)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                            ),
                          ),
                      ],
                    ),
                    title: Text(m['name']?.toString() ?? ''),
                    subtitle: Text('Active: ${_formatDuration(m['activeSeconds'] as int? ?? 0)} · Solved: ${m['queriesSolved'] ?? 0}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AdminManagerActivityDetailScreen(id: m['id'], name: m['name']?.toString() ?? '')),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AdminManagerActivityDetailScreen extends ConsumerWidget {
  const AdminManagerActivityDetailScreen({super.key, required this.id, required this.name});

  final dynamic id;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: PortalHeader(title: name),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ref.read(adminRepositoryProvider).getManagerActivityDetail(id),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingState();
          if (snap.hasError) return ErrorState(message: '${snap.error}');
          final data = snap.data ?? {};
          final sessions = (data['sessions'] as List?) ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: StatTile(label: 'Active time', value: _formatDuration(data['activeSeconds'] as int? ?? 0), icon: Icons.timer_outlined)),
                  const SizedBox(width: 10),
                  Expanded(child: StatTile(label: 'Queries solved', value: '${data['queriesSolved'] ?? 0}', icon: Icons.task_alt)),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Session history'),
              if (sessions.isEmpty)
                const EmptyState(message: 'No sessions recorded', icon: Icons.history)
              else
                ...sessions.map((s) {
                  final m = (s as Map).cast<String, dynamic>();
                  final open = m['logout_at'] == null;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.login, color: open ? AppColors.success : Colors.grey),
                      title: Text('Login: ${m['login_at'] ?? ''}'),
                      subtitle: Text(open ? 'Still active' : 'Logout: ${m['logout_at']}'),
                      trailing: Text(m['ip']?.toString() ?? '', style: const TextStyle(fontSize: 11)),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
