import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import 'manager_providers.dart';
import '../../../core/widgets/common.dart';

/// Failed-payment drilldown: view a pay record, edit it, and retry the
/// payout. Reused by both the manager reports tab (against `/api/emp/*`) and
/// the admin payments tab (against `/api/admin/*`) — the update/repay calls
/// are injected so each caller can point at its own repository while sharing
/// this one UI.
class PayRecordDetailScreen extends ConsumerStatefulWidget {
  const PayRecordDetailScreen({
    super.key,
    required this.record,
    this.updatePayRecord,
    this.repayPayRecord,
  });

  final Map<String, dynamic> record;

  /// Defaults to the manager repository's `/api/emp/pay-records/:id` call.
  final Future<Map<String, dynamic>> Function(dynamic id, Map<String, dynamic> fields)? updatePayRecord;

  /// Defaults to the manager repository's `/api/emp/pay-records/:id/repay` call.
  final Future<Map<String, dynamic>> Function(dynamic id)? repayPayRecord;

  @override
  ConsumerState<PayRecordDetailScreen> createState() => _PayRecordDetailScreenState();
}

class _PayRecordDetailScreenState extends ConsumerState<PayRecordDetailScreen> {
  late final TextEditingController _payIdCtrl;
  late final TextEditingController _amountCtrl;
  bool _saving = false;
  bool _repaying = false;

  @override
  void initState() {
    super.initState();
    _payIdCtrl = TextEditingController(text: widget.record['pay_id']?.toString() ?? '');
    _amountCtrl = TextEditingController(text: widget.record['pay_amount']?.toString() ?? '');
  }

  @override
  void dispose() {
    _payIdCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  dynamic get _id => widget.record['id'];

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    return Scaffold(
      appBar: PortalHeader(title: 'Failed payment'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.danger.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['off_name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text('Trx: ${r['trx_id'] ?? '-'}'),
                  Text('Order: ${r['order_id'] ?? '-'}'),
                  Text('Pay to: ${r['pay_to'] ?? '-'}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(controller: _payIdCtrl, decoration: const InputDecoration(labelText: 'Pay ID (UPI / account details)')),
          const SizedBox(height: 12),
          TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pay amount')),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save changes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.replay),
                  label: const Text('Retry payout'),
                  onPressed: _repaying ? null : _repay,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updateFn = widget.updatePayRecord ?? ref.read(managerRepositoryProvider).updatePayRecord;
      final result = await updateFn(_id, {
        'pay_id': _payIdCtrl.text,
        'pay_amount': num.tryParse(_amountCtrl.text) ?? widget.record['pay_amount'],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Updated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _repay() async {
    setState(() => _repaying = true);
    try {
      final repayFn = widget.repayPayRecord ?? ref.read(managerRepositoryProvider).repayPayRecord;
      final result = await repayFn(_id);
      if (!mounted) return;
      final success = result['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? (success ? 'Payout retried' : 'Retry failed')),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
      if (success && mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _repaying = false);
    }
  }
}
