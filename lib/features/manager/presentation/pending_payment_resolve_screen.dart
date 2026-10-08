import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'manager_providers.dart';
import '../../../core/widgets/common.dart';

/// There's no GET endpoint for the manager portal's pending-payments queue
/// (empRoutes.js only exposes POST /pending-payments/resolve, reusing the
/// admin approval primitive) — so this screen takes a transaction ID
/// directly rather than listing a queue that the API doesn't expose here.
class PendingPaymentResolveScreen extends ConsumerStatefulWidget {
  const PendingPaymentResolveScreen({super.key});

  @override
  ConsumerState<PendingPaymentResolveScreen> createState() => _PendingPaymentResolveScreenState();
}

class _PendingPaymentResolveScreenState extends ConsumerState<PendingPaymentResolveScreen> {
  final _trxCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _trxCtrl.dispose();
    super.dispose();
  }

  Future<void> _resolve(bool approve) async {
    final trxId = _trxCtrl.text.trim();
    if (trxId.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final result = await ref.read(managerRepositoryProvider).resolvePendingPayment(trxId: trxId, approve: approve);
      if (!mounted) return;
      final success = result['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? (success ? 'Resolved' : 'Failed')),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
      if (success) _trxCtrl.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PortalHeader(title: 'Resolve pending payment'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _trxCtrl, decoration: const InputDecoration(labelText: 'Transaction ID', prefixIcon: Icon(Icons.tag))),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    onPressed: _submitting ? null : () => _resolve(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    onPressed: _submitting ? null : () => _resolve(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
