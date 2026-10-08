import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/common.dart';
import '../../presentation/admin_providers.dart';

class AdminRedeemCodesScreen extends ConsumerStatefulWidget {
  const AdminRedeemCodesScreen({super.key});

  @override
  ConsumerState<AdminRedeemCodesScreen> createState() => _AdminRedeemCodesScreenState();
}

class _AdminRedeemCodesScreenState extends ConsumerState<AdminRedeemCodesScreen> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(adminRepositoryProvider).getRedeemCodes();
  }

  void _reload() => setState(() => _future = ref.read(adminRepositoryProvider).getRedeemCodes());

  Future<void> _createCode() async {
    final valueCtrl = TextEditingController();
    final maxUsesCtrl = TextEditingController(text: '1');
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New redeem code', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              TextField(controller: valueCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Value (₹)')),
              const SizedBox(height: 12),
              TextField(controller: maxUsesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max uses')),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  try {
                    await ref.read(adminRepositoryProvider).createRedeemCode(
                          value: num.tryParse(valueCtrl.text) ?? 0,
                          maxUses: int.tryParse(maxUsesCtrl.text) ?? 1,
                        );
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                },
                child: const Text('Create'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    if (created == true) _reload();
  }

  Future<void> _toggle(dynamic id, bool isActive) async {
    try {
      await ref.read(adminRepositoryProvider).toggleRedeemCode(id, isActive);
      _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(icon: const Icon(Icons.add), label: const Text('New code'), onPressed: _createCode),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingState();
          if (snap.hasError) return ErrorState(message: '${snap.error}', onRetry: _reload);
          final codes = (snap.data?['codes'] as List?) ?? [];
          if (codes.isEmpty) return const EmptyState(message: 'No redeem codes yet', icon: Icons.redeem_outlined);
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: codes.length,
              itemBuilder: (context, i) {
                final c = (codes[i] as Map).cast<String, dynamic>();
                final isActive = c['is_active'] == 1 || c['is_active'] == true;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: statusColor(isActive ? 'active' : 'suspended').withValues(alpha: 0.12), child: const Icon(Icons.confirmation_number_outlined, size: 18)),
                    title: Text(c['code']?.toString() ?? ''),
                    subtitle: Text('₹${c['value'] ?? 0} · Uses: ${c['used_count'] ?? 0}/${c['max_uses'] ?? 1}'),
                    trailing: Switch(value: isActive, onChanged: (v) => _toggle(c['id'], v)),
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
