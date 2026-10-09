import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/common.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../presentation/sample_data.dart';
import '../../presentation/widgets/aff_user_avatar.dart';
import '../../presentation/widgets/affiliate_design.dart';
import 'offer_detail_screen.dart';
import 'offers_providers.dart';

class OffersListScreen extends ConsumerStatefulWidget {
  const OffersListScreen({super.key});

  @override
  ConsumerState<OffersListScreen> createState() => _OffersListScreenState();
}

class _OffersListScreenState extends ConsumerState<OffersListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _category;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  num _numOf(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

  @override
  Widget build(BuildContext context) {
    final rawAsync = ref.watch(offersListProvider);
    final sample = isSample(rawAsync);
    final offersAsync = withSample(rawAsync, SampleData.offers);

    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: AffHeader(
        title: 'Campaigns',
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
        onRefresh: () async => ref.refresh(offersListProvider.future),
        child: offersAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: 'Failed to load offers.\n$e', onRetry: () => ref.invalidate(offersListProvider)),
          data: (offers) {
            final categories = <String>{for (final o in offers) (o['category'] ?? '').toString()}..removeWhere((c) => c.isEmpty);
            final filtered = offers.where((o) {
              final name = (o['offer_name'] ?? o['offerName'] ?? '').toString().toLowerCase();
              final matchesQuery = _query.isEmpty || name.contains(_query.toLowerCase());
              final matchesCat = _category == null || (o['category'] ?? '').toString() == _category;
              return matchesQuery && matchesCat;
            }).toList();
            final poolTotal = offers.fold<num>(0, (sum, o) => sum + _numOf(o['payout'] ?? o['maxPayout'] ?? o['payoutAmount']));

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
              children: [
                if (sample) SampleDataBanner(onRetry: () => ref.invalidate(offersListProvider)),
                FadeSlideIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Campaigns Directory', style: AffText.jakarta(21, FontWeight.w800, letterSpacing: -0.4, height: 1.2)),
                      const SizedBox(height: 4),
                      Text('Promote verified advertiser offers and earn instant commissions',
                          style: AffText.jakarta(12.5, FontWeight.w500, color: AffColors.inkMuted, height: 1.45)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  index: 1,
                  child: Row(
                    children: [
                      Expanded(child: _StatBox(label: 'OFFERS', value: '${offers.length}')),
                      const SizedBox(width: 10),
                      Expanded(child: _StatBox(label: 'POOL', value: '₹${poolTotal.toStringAsFixed(0)}')),
                      const SizedBox(width: 10),
                      Expanded(child: _StatBox(label: 'CATS', value: '${categories.length}')),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  index: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [BoxShadow(color: const Color(0xFF3C1478).withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 3))],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, size: 18, color: AffColors.inkHint),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _searchCtrl,
                                  onChanged: (v) => setState(() => _query = v),
                                  style: AffText.jakarta(12.5, FontWeight.w500),
                                  decoration: InputDecoration(
                                    filled: false,
                                    isDense: true,
                                    hintText: 'Search campaigns',
                                    hintStyle: AffText.jakarta(12.5, FontWeight.w500, color: AffColors.inkHint),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterPill(label: 'All', selected: _category == null, onTap: () => setState(() => _category = null)),
                      if (categories.contains('Demat')) ...[
                        const SizedBox(width: 8),
                        _FilterPill(label: 'Demat', selected: _category == 'Demat', onTap: () => setState(() => _category = _category == 'Demat' ? null : 'Demat')),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const EmptyState(message: 'No live offers right now', icon: Icons.local_offer_outlined)
                else
                  for (var i = 0; i < filtered.length; i++)
                    FadeSlideIn(
                      index: 3 + i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _OfferCard(offer: filtered[i], sample: sample),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AffCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AffText.jakarta(9, FontWeight.w700, color: AffColors.inkFaint, letterSpacing: 0.72)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: AffText.number(22, FontWeight.w700))),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AffColors.purpleEnd : Colors.white,
          borderRadius: BorderRadius.circular(99),
          boxShadow: selected ? null : [BoxShadow(color: const Color(0xFF3C1478).withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Text(label, style: AffText.jakarta(12, selected ? FontWeight.w700 : FontWeight.w600, color: selected ? Colors.white : AffColors.inkMuted)),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, this.sample = false});
  final Map<String, dynamic> offer;
  final bool sample;

  @override
  Widget build(BuildContext context) {
    final offId = (offer['off_id'] ?? offer['offId'])?.toString() ?? '';
    final name = (offer['offer_name'] ?? offer['offerName'] ?? '').toString();
    final title = (offer['offer_title'] ?? offer['offerTitle'] ?? '').toString();
    final category = (offer['category'] ?? '').toString();
    final logo = offer['logo']?.toString();
    final payout = offer['payout'] ?? offer['maxPayout'] ?? offer['payoutAmount'];
    final trimmed = name.trim();
    final abbr = trimmed.isEmpty ? '?' : trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();

    final accent = AffColors.colorFor(name);
    return AffCard(
      radius: 22,
      wash: accent,
      padding: const EdgeInsets.all(15),
      onTap: () {
        if (sample) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sample offer — reconnect to open real campaigns')));
          return;
        }
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => OfferDetailScreen(offId: offId)));
      },
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AffColors.gradientFor(name),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: logo != null && logo.isNotEmpty
                    ? Image.network(
                        logo.startsWith('http') ? logo : '${ApiConfig.baseUrl}$logo',
                        fit: BoxFit.cover,
                        width: 42,
                        height: 42,
                        errorBuilder: (_, __, ___) => Text(abbr, style: AffText.number(13, FontWeight.w700, color: Colors.white)),
                      )
                    : Text(abbr, style: AffText.number(13, FontWeight.w700, color: Colors.white)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AffText.jakarta(14, FontWeight.w700)),
                    if (category.isNotEmpty || title.isNotEmpty)
                      Text(
                        [if (category.isNotEmpty) category, if (title.isNotEmpty) title].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AffText.jakarta(11, FontWeight.w500, color: AffColors.inkFaint),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: AffColors.liveBg, borderRadius: BorderRadius.circular(99)),
                child: Text('LIVE', style: AffText.jakarta(10, FontWeight.w700, color: AffColors.live)),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (payout != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PAYOUT', style: AffText.jakarta(9.5, FontWeight.w700, color: AffColors.inkFaint, letterSpacing: 0.76)),
                    Text('₹$payout', style: AffText.number(19, FontWeight.w700, color: accent)),
                  ],
                )
              else
                const SizedBox.shrink(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                decoration: BoxDecoration(
                  gradient: AffColors.gradientFor(name),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.38), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Text('View Offer ↗', style: AffText.jakarta(12.5, FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
