import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../wallet/presentation/wallet_providers.dart';

class RedeemScreen extends ConsumerStatefulWidget {
  const RedeemScreen({super.key});

  @override
  ConsumerState<RedeemScreen> createState() => _RedeemScreenState();
}

class _RedeemScreenState extends ConsumerState<RedeemScreen> {
  final _codeCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final client = await ref.read(apiClientProvider.future);
      final res = await client.dio.post('/api/redeem', data: {'code': code});
      if (!mounted) return;
      final success = res.isSuccess;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty ? res.message : (success ? 'Code redeemed!' : 'Redemption failed')),
          backgroundColor: success ? AppColors.success : AppColors.danger,
        ),
      );
      if (success) {
        _codeCtrl.clear();
        ref.invalidate(walletSummaryProvider);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EEFB),
      appBar: const PortalHeader(title: 'Redeem code'),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GradientHeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.redeem, color: Colors.white, size: 32),
                  SizedBox(height: 10),
                  Text('Have a reward code?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Redeem it below to instantly credit your wallet.', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Redeem code', prefixIcon: Icon(Icons.confirmation_number_outlined)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting ? null : _redeem,
              child: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Redeem'),
            ),
          ],
        ),
      ),
    );
  }
}
