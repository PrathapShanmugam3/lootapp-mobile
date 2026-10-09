import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/widgets/affiliate_design.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../wallet/presentation/wallet_providers.dart';
import '../../../../core/widgets/app_toast.dart';

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
      showToast(
        context,
        res.message.isNotEmpty ? res.message : (success ? 'Code redeemed!' : 'Redemption failed'),
        type: success ? ToastType.success : ToastType.error,
        title: success ? 'Code redeemed' : null,
      );
      if (success) {
        _codeCtrl.clear();
        ref.invalidate(walletSummaryProvider);
      }
    } catch (e) {
      if (mounted) showErrorToast(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: const AffHeader(title: 'Redeem code', subtitle: 'Credit a reward code to your wallet'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AffHeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.redeem_rounded, color: AffColors.gold, size: 34),
                  SizedBox(height: 10),
                  Text('Have a reward code?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.4)),
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
            GradientButton(label: 'Redeem', loading: _submitting, onPressed: _redeem),
          ],
        ),
      ),
    );
  }
}
