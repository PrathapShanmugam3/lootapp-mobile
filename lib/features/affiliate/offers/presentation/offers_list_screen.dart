import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/common.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../presentation/profile_menu_sheet.dart';
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
          AffHeaderAvatar(
            initials: 'TA',
            onTap: () => showProfileMenuSheet(context, ref, initials: 'TA', name: ''),
          ),
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
                  child: Text('Campaigns Directory', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AffColors.ink)),
                ),
                const SizedBox(height: 2),
                const FadeSlideIn(
                  index: 1,
                  child: Text('Promote verified advertiser offers and earn instant commissions',
                      style: TextStyle(fontSize: 12.5, color: AffColors.inkMuted, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  index: 2,
                  child: Row(
                    children: [
                      Expanded(child: _StatChip(label: 'OFFERS', value: '${offers.length}')),
                      const SizedBox(width: 10),
                      Expanded(child: _StatChip(label: 'POOL', value: '₹${poolTotal.toStringAsFixed(0)}')),
                      const SizedBox(width: 10),
                      Expanded(child: _StatChip(label: 'CATS', value: '${categories.length}')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  index: 3,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AffColors.cardShadow),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (v) => setState(() => _query = v),
                            decoration: const InputDecoration(
                              hintText: 'Search campaigns',
                              prefixIcon: Icon(Icons.search_rounded, size: 20),
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
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AffCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AffColors.inkFaint, letterSpacing: 0.8)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AffColors.ink)),
          ),
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
            boxShadow: selected ? AffColors.cardShadow : null,
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
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(gradient: AffColors.gradient),
              alignment: Alignment.center,
              child: logo != null && logo.isNotEmpty
                  ? Image.network(
                      logo.startsWith('http') ? logo : '${ApiConfig.baseUrl}$logo',
                      fit: BoxFit.cover,
                      width: 46,
                      height: 46,
                      errorBuilder: (_, __, ___) => Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    )
                  : Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AffColors.ink), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (title.isNotEmpty || category.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      [if (category.isNotEmpty) category, if (title.isNotEmpty) title].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AffColors.inkMuted, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 8),
                if (payout != null) ...[
                  const Text('PAYOUT', style: TextStyle(color: AffColors.inkFaint, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                  Text('₹$payout', style: const TextStyle(color: AffColors.purpleEnd, fontWeight: FontWeight.w900, fontSize: 16)),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: AffColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: const Text('LIVE', style: TextStyle(color: AffColors.success, fontSize: 10.5, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(gradient: AffColors.gradient, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('View Offer', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    SizedBox(width: 2),
                    Icon(Icons.north_east, color: Colors.white, size: 12),
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
