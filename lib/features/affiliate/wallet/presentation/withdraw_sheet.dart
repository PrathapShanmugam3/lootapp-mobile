import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import 'wallet_providers.dart';

class WithdrawSheet extends ConsumerStatefulWidget {
  const WithdrawSheet({super.key});

  @override
  ConsumerState<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<WithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'upi';
  final _amountCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _upiCtrl.dispose();
    _accountCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gatewayAsync = ref.watch(gatewayStatusProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: gatewayAsync.when(
            loading: () => const SizedBox(height: 200, child: LoadingState(compact: true)),
            error: (e, _) => ErrorState(message: 'Could not load withdrawal options.\n$e'),
            data: (activeTypes) {
              if (!activeTypes.contains(_type) && activeTypes.isNotEmpty) {
                _type = activeTypes.first;
              }
              return Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(4)),
                    ),
                    Text('Withdraw funds', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    if (activeTypes.isEmpty)
                      const EmptyState(message: 'Withdrawals are currently unavailable', icon: Icons.block)
                    else ...[
                      SegmentedButton<String>(
                        segments: [
                          if (activeTypes.contains('upi')) const ButtonSegment(value: 'upi', label: Text('UPI'), icon: Icon(Icons.qr_code)),
                          if (activeTypes.contains('bank')) const ButtonSegment(value: 'bank', label: Text('Bank'), icon: Icon(Icons.account_balance)),
                        ],
                        selected: {_type},
                        onSelectionChanged: (s) => setState(() => _type = s.first),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount (₹10 - ₹50,000)'),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n < 10 || n > 50000) return 'Enter an amount between ₹10 and ₹50,000';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_type == 'upi')
                        TextFormField(
                          controller: _upiCtrl,
                          decoration: const InputDecoration(labelText: 'UPI ID'),
                          validator: (v) => (v == null || !RegExp(r'^[a-zA-Z0-9.\-_]+@[a-zA-Z0-9]+$').hasMatch(v)) ? 'Enter a valid UPI ID' : null,
                        )
                      else ...[
                        TextFormField(
                          controller: _accountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Account number'),
                          validator: (v) => (v == null || !RegExp(r'^[0-9]{9,18}$').hasMatch(v)) ? 'Enter a valid account number' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ifscCtrl,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(labelText: 'IFSC code'),
                          validator: (v) => (v == null || !RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(v.toUpperCase())) ? 'Enter a valid IFSC code' : null,
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _submitting ? null : () => _submit(context),
                          child: _submitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Submit request'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final result = await ref.read(walletRepositoryProvider).withdraw(
            type: _type,
            amount: double.parse(_amountCtrl.text),
            upiId: _type == 'upi' ? _upiCtrl.text : null,
            accountNo: _type == 'bank' ? _accountCtrl.text : null,
            ifscCode: _type == 'bank' ? _ifscCtrl.text : null,
          );
      if (!context.mounted) return;
      final success = result['success'] == true;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ?? (success ? 'Withdrawal requested' : 'Withdrawal failed')),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
