import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/common.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../presentation/sample_data.dart';
import '../../presentation/widgets/aff_user_avatar.dart';
import '../../presentation/widgets/affiliate_design.dart';
import 'wallet_providers.dart';
import 'withdraw_sheet.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawSummary = ref.watch(walletSummaryProvider);
    final rawTxns = ref.watch(transactionsProvider);
    final summarySample = isSample(rawSummary);
    final txnsSample = isSample(rawTxns);
    final summaryAsync = withSample(rawSummary, SampleData.walletSummary);
    final txnsAsync = withSample(rawTxns, SampleData.transactions);

    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: AffHeader(
        title: 'Payouts',
        subtitle: 'LootHat Affiliate',
        actions: [
          AffHeaderIcon(
            icon: Icons.notifications_none_rounded,
            showDot: true,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          const AffUserAvatar(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletSummaryProvider);
          ref.invalidate(transactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
          children: [
            if (summarySample || txnsSample)
              SampleDataBanner(onRetry: () {
                ref.invalidate(walletSummaryProvider);
                ref.invalidate(transactionsProvider);
              }),
            FadeSlideIn(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wallet & Payouts', style: AffText.jakarta(21, FontWeight.w800, letterSpacing: -0.4, height: 1.2)),
                  const SizedBox(height: 4),
                  Text('Manage available earnings and withdraw directly to your account', style: AffText.jakarta(12.5, FontWeight.w500, color: AffColors.inkMuted, height: 1.45)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            summaryAsync.when(
              loading: () => const SizedBox(height: 220, child: LoadingState(compact: true)),
              error: (e, _) => ErrorState(message: 'Failed to load wallet.\n$e', onRetry: () => ref.invalidate(walletSummaryProvider)),
              data: (summary) => Column(
                children: [
                  FadeSlideIn(
                    index: 1,
                    child: AffHeroCard(
                      radius: 24,
                      gradient: AffColors.walletGradient,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AVAILABLE BALANCE', style: AffText.jakarta(10.5, FontWeight.w700, color: Colors.white.withValues(alpha: 0.85), letterSpacing: 1.05)),
                          const SizedBox(height: 4),
                          AnimatedCount(value: summary.balance, format: _currency.format, style: AffText.number(38, FontWeight.w700, color: Colors.white, height: 1.1)),
                          const SizedBox(height: 14),
                          PressableScale(
                            onTap: () => _openWithdrawSheet(context, ref, sample: summarySample),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(99),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 8))],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(99),
                                  onTap: () => _openWithdrawSheet(context, ref, sample: summarySample),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.bolt_rounded, size: 18, color: AffColors.purple),
                                        const SizedBox(width: 6),
                                        Text('Withdraw Funds', style: AffText.jakarta(14, FontWeight.w800, color: AffColors.purple)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _HeroMini(label: 'TOTAL EARNED', value: _currency.format(summary.totalEarned)),
                              const SizedBox(width: 26),
                              _HeroMini(label: 'WITHDRAWN', value: _currency.format(summary.totalWithdrawn)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(index: 2, child: _RedeemCard(ref: ref)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            txnsAsync.when(
              loading: () => const SizedBox(height: 120, child: LoadingState(compact: true)),
              error: (e, _) => ErrorState(message: 'Failed to load transactions.\n$e', onRetry: () => ref.invalidate(transactionsProvider)),
              data: (txns) => FadeSlideIn(
                index: 3,
                child: AffCard(
                  radius: 22,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Transaction History', style: AffText.jakarta(14.5, FontWeight.w800)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AffColors.chipLilac, borderRadius: BorderRadius.circular(99)),
                            child: Text('${txns.length} records', style: AffText.jakarta(10.5, FontWeight.w700, color: AffColors.purpleEnd)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (txns.isEmpty)
                        const EmptyState(message: 'No transactions yet', icon: Icons.receipt_long_outlined)
                      else ...[
                        for (var i = 0; i < txns.length; i++) ...[
                          if (i > 0) const SizedBox(height: 12),
                          _TransactionRow(txn: txns[i]),
                        ],
                        if (!txnsSample && ref.read(transactionsProvider.notifier).hasMore)
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Center(
                              child: GestureDetector(
                                onTap: () => ref.read(transactionsProvider.notifier).loadMore(),
                                child: Text('Load more ↓', style: AffText.jakarta(12, FontWeight.w700, color: AffColors.purpleEnd)),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openWithdrawSheet(BuildContext context, WidgetRef ref, {bool sample = false}) {
    if (sample) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reconnect to the server to withdraw')));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const WithdrawSheet(),
    ).then((_) {
      ref.invalidate(walletSummaryProvider);
      ref.invalidate(transactionsProvider);
    });
  }
}

class _HeroMini extends StatelessWidget {
  const _HeroMini({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AffText.jakarta(9.5, FontWeight.w700, color: Colors.white.withValues(alpha: 0.8), letterSpacing: 0.85)),
        const SizedBox(height: 2),
        Text(value, style: AffText.number(18, FontWeight.w700, color: Colors.white)),
      ],
    );
  }
}

/// 1.5px dashed rounded border (the gift-code field).
class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) => old.color != color || old.radius != radius;
}

class _RedeemCard extends ConsumerStatefulWidget {
  const _RedeemCard({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_RedeemCard> createState() => _RedeemCardState();
}

class _RedeemCardState extends ConsumerState<_RedeemCard> {
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
          backgroundColor: success ? AffColors.success : AffColors.danger,
        ),
      );
      _codeCtrl.clear();
      if (success) {
        ref.invalidate(walletSummaryProvider);
      }
    } catch (e) {
      _codeCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AffCard(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Redeem promo code', style: AffText.jakarta(14.5, FontWeight.w800)),
          const SizedBox(height: 10),
          CustomPaint(
            painter: _DashedBorderPainter(color: const Color(0xFFDDD2F7), radius: 14),
            child: Container(
              decoration: BoxDecoration(color: AffColors.pageBg, borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: _codeCtrl,
                maxLength: 50,
                textCapitalization: TextCapitalization.characters,
                style: AffText.number(13, FontWeight.w600, letterSpacing: 1.56),
                decoration: InputDecoration(
                  filled: false,
                  hintText: 'ENTER GIFT CODE',
                  hintStyle: AffText.number(13, FontWeight.w600, color: AffColors.inkHint, letterSpacing: 1.56),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _submitting ? null : _redeem,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(gradient: AffColors.gradient, borderRadius: BorderRadius.circular(14)),
              child: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Redeem', style: AffText.jakarta(13.5, FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.txn});

  final dynamic txn;

  @override
  Widget build(BuildContext context) {
    final isDebit = txn.type == 'debit';
    final color = isDebit ? AffColors.danger : AffColors.success;
    final status = (txn.status ?? '').toString();
    final settled = status.toLowerCase() == 'success';
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: AffColors.pageBg, borderRadius: BorderRadius.circular(11)),
          child: Icon(isDebit ? Icons.north_east_rounded : Icons.south_west_rounded, size: 15, color: color),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text((txn.comment ?? txn.type).toString(), maxLines: 1, overflow: TextOverflow.ellipsis, style: AffText.jakarta(12.5, FontWeight.w700)),
              Text('${txn.date ?? ''} ${txn.time ?? ''}'.trim(), style: AffText.jakarta(10.5, FontWeight.w500, color: AffColors.inkFaint)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${isDebit ? '-' : '+'}${_currency.format(txn.amount)}', style: AffText.number(13, FontWeight.w700, color: color)),
            if (!settled && status.isNotEmpty) ...[
              const SizedBox(height: 3),
              StatusChip(text: status, color: statusColor(status)),
            ],
          ],
        ),
      ],
    );
  }
}
