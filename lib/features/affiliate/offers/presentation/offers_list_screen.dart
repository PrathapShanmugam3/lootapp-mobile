import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/common.dart';
import '../../notifications/presentation/notifications_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(offersListProvider);

    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: AffHeader(
        title: 'Campaigns',
        subtitle: 'LootHat Affiliate',
        actions: [
          AffHeaderIcon(
            icon: Icons.notifications_outlined,
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
            var filtered = offers.where((o) {
              final name = (o['offer_name'] ?? o['offerName'] ?? '').toString().toLowerCase();
              final matchesQuery = _query.isEmpty || name.contains(_query.toLowerCase());
              final matchesCat = _category == null || (o['category'] ?? '').toString() == _category;
              return matchesQuery && matchesCat;
            }).toList();

            final poolTotal = offers.fold<num>(0, (sum, o) => sum + (_numOf(o['payout'] ?? o['maxPayout'] ?? o['payoutAmount'])));

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
              children: [
                FadeSlideIn(
                  child: AffCard(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(child: _StatChip(label: 'OFFERS', value: '${offers.length}', icon: Icons.local_offer_rounded)),
                          const VerticalDivider(width: 1, color: AffColors.hairline),
                          Expanded(child: _StatChip(label: 'PAYOUT POOL', value: '₹${poolTotal.toStringAsFixed(0)}', icon: Icons.payments_rounded, gold: true)),
                          const VerticalDivider(width: 1, color: AffColors.hairline),
                          Expanded(child: _StatChip(label: 'CATEGORIES', value: '${categories.length}', icon: Icons.category_rounded)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  index: 3,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AffColors.hairline), boxShadow: AffColors.cardShadow),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _query = v),
                            decoration: const InputDecoration(
                              filled: false,
                              hintText: 'Search campaigns',
                              prefixIcon: Icon(Icons.search_rounded, size: 21, color: AffColors.inkFaint),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _FilterPill(label: 'All', selected: _category == null, onTap: () => setState(() => _category = null)),
                      if (categories.contains('Demat')) ...[
                        const SizedBox(width: 8),
                        _FilterPill(label: 'Demat', selected: _category == 'Demat', onTap: () => setState(() => _category = _category == 'Demat' ? null : 'Demat')),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const EmptyState(message: 'No live offers right now', icon: Icons.local_offer_outlined)
                else
                  for (var i = 0; i < filtered.length; i++)
                    FadeSlideIn(
                      index: 4 + i,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OfferCard(offer: filtered[i]),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }

  num _numOf(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.icon, this.gold = false});
  final String label;
  final String value;
  final IconData icon;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final color = gold ? const Color(0xFFE08A1E) : AffColors.purpleEnd;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AffColors.ink, letterSpacing: -0.5)),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AffColors.inkFaint, letterSpacing: 0.9)),
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
    return Material(
      color: selected ? null : Colors.white,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AffColors.gradient : null,
            borderRadius: BorderRadius.circular(999),
            border: selected ? null : Border.all(color: AffColors.hairline),
            boxShadow: selected ? [BoxShadow(color: AffColors.purpleEnd.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))] : null,
          ),
          child: Text(label, style: TextStyle(color: selected ? Colors.white : AffColors.inkMuted, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});
  final Map<String, dynamic> offer;

  @override
  Widget build(BuildContext context) {
    final offId = (offer['off_id'] ?? offer['offId'])?.toString() ?? '';
    final name = (offer['offer_name'] ?? offer['offerName'] ?? '').toString();
    final title = (offer['offer_title'] ?? offer['offerTitle'] ?? '').toString();
    final category = (offer['category'] ?? '').toString();
    final logo = offer['logo']?.toString();
    final payout = offer['payout'] ?? offer['maxPayout'] ?? offer['payoutAmount'];
    final initials = name.isNotEmpty ? name.trim().substring(0, name.trim().length >= 2 ? 2 : 1).toUpperCase() : '?';

    return AffCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OfferDetailScreen(offId: offId))),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(gradient: AffColors.gradient),
                  alignment: Alignment.center,
                  child: logo != null && logo.isNotEmpty
                      ? Image.network(
                          logo.startsWith('http') ? logo : '${ApiConfig.baseUrl}$logo',
                          fit: BoxFit.cover,
                          width: 52,
                          height: 52,
                          errorBuilder: (_, __, ___) => Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                        )
                      : Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: AffColors.ink, letterSpacing: -0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (title.isNotEmpty || category.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          [if (category.isNotEmpty) category, if (title.isNotEmpty) title].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AffColors.inkMuted, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(color: AffColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: AffColors.success, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    const Text('LIVE', style: TextStyle(color: AffColors.success, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (payout != null)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(color: AffColors.pageBg, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.payments_rounded, size: 18, color: Color(0xFFE08A1E)),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PAYOUT', style: TextStyle(color: AffColors.inkFaint, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.9)),
                            Text('₹$payout', style: const TextStyle(color: AffColors.ink, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.4)),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Spacer(),
              const SizedBox(width: 10),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  gradient: AffColors.gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AffColors.purpleEnd.withValues(alpha: 0.32), blurRadius: 14, offset: const Offset(0, 6))],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Promote', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
