import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/common.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../presentation/profile_menu_sheet.dart';
import '../../presentation/widgets/affiliate_design.dart';
import 'wallet_providers.dart';
import 'withdraw_sheet.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(walletSummaryProvider);
    final txnsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: AffHeader(
        title: 'Payouts',
        subtitle: 'LootHat Affiliate',
        actions: [
          AffHeaderIcon(
            icon: Icons.notifications_outlined,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          AffHeaderAvatar(initials: 'TA', onTap: () => showProfileMenuSheet(context, ref, initials: 'TA', name: '')),
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
            FadeSlideIn(
              child: Text('Wallet & Payouts', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AffColors.ink)),
            ),
            const SizedBox(height: 2),
            const FadeSlideIn(
              index: 1,
              child: Text('Manage available earnings and withdraw directly to your account',
                  style: TextStyle(fontSize: 12.5, color: AffColors.inkMuted, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 16),
            summaryAsync.when(
              loading: () => const SizedBox(height: 220, child: LoadingState(compact: true)),
              error: (e, _) => ErrorState(message: 'Failed to load wallet.\n$e', onRetry: () => ref.invalidate(walletSummaryProvider)),
              data: (summary) => Column(
                children: [
                  FadeSlideIn(
                    index: 2,
                    child: AffHeroCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AVAILABLE BALANCE',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.white.withValues(alpha: 0.78))),
                          const SizedBox(height: 4),
                          Text(
                            _currency.format(summary.balance),
                            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: PressableScale(
                              onTap: () => _openWithdrawSheet(context, ref),
                              child: Material(
                                color: Colors.white,
                                shape: const StadiumBorder(),
                                child: InkWell(
                                  customBorder: const StadiumBorder(),
                                  onTap: () => _openWithdrawSheet(context, ref),
                                  child: const SizedBox(
                                    height: 48,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.bolt_rounded, color: AffColors.purpleEnd, size: 18),
                                        SizedBox(width: 6),
                                        Text('Withdraw Funds', style: TextStyle(color: AffColors.purpleEnd, fontWeight: FontWeight.w800, fontSize: 14.5)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _HeroMini(label: 'TOTAL EARNED', value: _currency.format(summary.totalEarned)),
                              ),
                              Container(width: 1, height: 30, color: Colors.white.withValues(alpha: 0.25)),
                              Expanded(
                                child: _HeroMini(label: 'WITHDRAWN', value: _currency.format(summary.totalWithdrawn)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(index: 3, child: _RedeemCard(ref: ref)),
                ],
              ),
            ),
            const SizedBox(height: 26),
            const AffSectionHeader(title: 'Transaction History'),
            txnsAsync.when(
              loading: () => const SizedBox(height: 120, child: LoadingState(compact: true)),
              error: (e, _) => ErrorState(message: 'Failed to load transactions.\n$e', onRetry: () => ref.invalidate(transactionsProvider)),
              data: (txns) {
                if (txns.isEmpty) {
                  return const EmptyState(message: 'No transactions yet', icon: Icons.receipt_long_outlined);
                }
                return Column(
                  children: [
                    FadeSlideIn(
                      index: 4,
                      child: AffCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var i = 0; i < txns.length; i++) ...[
                              if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16, color: AffColors.hairline),
                              _TransactionRow(txn: txns[i]),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (ref.read(transactionsProvider.notifier).hasMore)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: OutlinedButton.icon(
                          onPressed: () => ref.read(transactionsProvider.notifier).loadMore(),
                          icon: const Icon(Icons.expand_more_rounded),
                          label: const Text('Load more'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openWithdrawSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
        Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.75), letterSpacing: 0.7)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
      ],
    );
  }
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
    return AffCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Redeem promo code', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AffColors.ink)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: AffColors.pageBg, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'ENTER GIFT CODE',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Material(
              color: null,
              shape: const StadiumBorder(),
              child: Ink(
                decoration: const BoxDecoration(gradient: AffColors.gradient, shape: BoxShape.rectangle, borderRadius: BorderRadius.all(Radius.circular(999))),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: _submitting ? null : _redeem,
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: _submitting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Redeem', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5)),
                    ),
                  ),
                ),
              ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(13)),
            child: Icon(isDebit ? Icons.north_east_rounded : Icons.south_west_rounded, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.comment ?? txn.type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AffColors.ink),
                ),
                const SizedBox(height: 2),
                Text('${txn.date ?? ''} ${txn.time ?? ''}'.trim(), style: const TextStyle(fontSize: 11.5, color: AffColors.inkMuted)),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isDebit ? '-' : '+'}${_currency.format(txn.amount)}',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: color),
              ),
              const SizedBox(height: 4),
              StatusChip(text: txn.status, color: statusColor(txn.status)),
            ],
          ),
        ],
      ),
    );
  }
}
