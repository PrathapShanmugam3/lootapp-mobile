import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/widgets/affiliate_design.dart';
import 'offers_providers.dart';

class OfferDetailScreen extends ConsumerWidget {
  const OfferDetailScreen({super.key, required this.offId});

  final String offId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(offerDetailProvider(offId));

    return Scaffold(
      backgroundColor: AffColors.pageBg,
      body: detailAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: 'Failed to load offer.\n$e', onRetry: () => ref.invalidate(offerDetailProvider(offId))),
        data: (data) => _OfferDetailBody(offId: offId, data: data),
      ),
    );
  }
}

class _OfferDetailBody extends ConsumerStatefulWidget {
  const _OfferDetailBody({required this.offId, required this.data});

  final String offId;
  final Map<String, dynamic> data;

  @override
  ConsumerState<_OfferDetailBody> createState() => _OfferDetailBodyState();
}

class _OfferDetailBodyState extends ConsumerState<_OfferDetailBody> {
  late Map<String, dynamic> offer;
  late Map<String, dynamic> referralLink;
  late List availableThemes;
  String? selectedTheme;
  bool savingTheme = false;
  bool savingSplit = false;
  Map<int, double> userPo = {};
  Map<int, double> referPo = {};
  bool _bannerFailed = false;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  void _hydrate() {
    offer = (widget.data['offer'] as Map?)?.cast<String, dynamic>() ?? {};
    referralLink = (widget.data['referralLink'] as Map?)?.cast<String, dynamic>() ?? {};
    availableThemes = (widget.data['availableThemes'] as List?) ??
        [
          {'key': 'classic', 'label': 'Classic'},
          {'key': 'minimal', 'label': 'Minimal'},
          {'key': 'bold', 'label': 'Bold'},
        ];
    selectedTheme = referralLink['landingTheme']?.toString();
    final split = (referralLink['currentSplit'] as List?) ?? [];
    for (final s in split) {
      final m = (s as Map).cast<String, dynamic>();
      final idx = m['index'] as int;
      userPo[idx] = (m['userPayout'] as num?)?.toDouble() ?? 0;
      referPo[idx] = (m['referPayout'] as num?)?.toDouble() ?? 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = (offer['events'] as List?) ?? [];
    final bannerImage = offer['bannerImage']?.toString();
    final logo = offer['logo']?.toString();
    final totalPayout = offer['totalPayout'];

    final hasBanner = bannerImage != null && bannerImage.isNotEmpty;

    final category = offer['category']?.toString() ?? '';
    final offerTitle = offer['offerTitle']?.toString() ?? '';
    final logoUrl = (logo != null && logo.isNotEmpty) ? (logo.startsWith('http') ? logo : '${ApiConfig.baseUrl}$logo') : null;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: [BoxShadow(color: AffColors.midnightSoft.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              child: DecoratedBox(
                decoration: const BoxDecoration(gradient: AffColors.heroGradient),
                child: Stack(
                  children: [
                    const Positioned.fill(child: DecorativeOrbs()),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Material(
                              color: Colors.white.withValues(alpha: 0.14),
                              shape: CircleBorder(side: BorderSide(color: Colors.white.withValues(alpha: 0.22))),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => Navigator.of(context).maybePop(),
                                child: const SizedBox(width: 40, height: 40, child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 17)),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: logoUrl != null
                                        ? Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.local_offer_rounded, color: AffColors.purpleEnd))
                                        : const Icon(Icons.local_offer_rounded, color: AffColors.purpleEnd),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          offer['offerName']?.toString() ?? '',
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                                        ),
                                        if (category.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
                                              child: Text(category, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (offerTitle.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(offerTitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 13.5, height: 1.4)),
                              ),
                            ],
                            const SizedBox(height: 18),
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('TOTAL PAYOUT', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                                      const SizedBox(height: 2),
                                      Text('₹$totalPayout', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AffColors.gold, letterSpacing: -1)),
                                    ],
                                  ),
                                  const Icon(Icons.workspace_premium_rounded, color: AffColors.gold, size: 34),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasBanner && !_bannerFailed) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 16 / 7,
                      child: Image.network(
                        bannerImage.startsWith('http') ? bannerImage : '${ApiConfig.baseUrl}$bannerImage',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && !_bannerFailed) setState(() => _bannerFailed = true);
                          });
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _referralLinkCard(context),
                const SizedBox(height: 22),
                if (availableThemes.isNotEmpty) ...[
                  const AffSectionHeader(title: 'Landing page theme'),
                  _themePicker(context),
                  const SizedBox(height: 22),
                ],
                if (events.isNotEmpty) ...[
                  const AffSectionHeader(title: 'Payout events'),
                  _eventsCard(context, events),
                  const SizedBox(height: 22),
                ],
                if ((offer['steps']?.toString() ?? '').isNotEmpty) _textSection(context, 'How it works', offer['steps']),
                if ((offer['offerBenefits']?.toString() ?? '').isNotEmpty) _textSection(context, 'Benefits', offer['offerBenefits']),
                if ((offer['offerFeesCharges']?.toString() ?? '').isNotEmpty) _textSection(context, 'Fees & charges', offer['offerFeesCharges']),
                if ((offer['terms']?.toString() ?? '').isNotEmpty) _textSection(context, 'Terms', offer['terms']),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _referralLinkCard(BuildContext context) {
    final offerLink = referralLink['offerLink']?.toString() ?? '';
    final referLink = referralLink['referLink']?.toString() ?? '';
    return AffCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AffIconChip(icon: Icons.link_rounded, size: 38, solid: true),
              const SizedBox(width: 12),
              const Text('Your referral links', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5, color: AffColors.ink)),
            ],
          ),
          const SizedBox(height: 14),
          _linkRow(context, 'Offer link', offerLink),
          const SizedBox(height: 10),
          _linkRow(context, 'Refer link', referLink),
        ],
      ),
    );
  }

  Widget _linkRow(BuildContext context, String label, String link) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AffColors.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AffColors.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AffColors.inkFaint, letterSpacing: 0.6)),
                const SizedBox(height: 2),
                Text(link, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AffColors.ink)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: AffColors.purpleEnd.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
            child: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16, color: AffColors.purpleEnd),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: link));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied')));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _themePicker(BuildContext context) {
    return AffCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: availableThemes.map((t) {
          final m = (t as Map).cast<String, dynamic>();
          final key = m['key']?.toString() ?? '';
          final label = m['label']?.toString() ?? key;
          final selected = key == selectedTheme;
          return GestureDetector(
            onTap: savingTheme
                ? null
                : () async {
                    setState(() => savingTheme = true);
                    try {
                      await ref.read(offersRepositoryProvider).updateLandingTheme(widget.offId, key);
                      setState(() => selectedTheme = key);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update theme: $e')));
                      }
                    } finally {
                      if (mounted) setState(() => savingTheme = false);
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: selected ? AffColors.gradient : null,
                color: selected ? null : AffColors.pageBg,
                borderRadius: BorderRadius.circular(999),
                border: selected ? null : Border.all(color: AffColors.hairline),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AffColors.inkMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _eventsCard(BuildContext context, List events) {
    return AffCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in events) _eventTile(context, (e as Map).cast<String, dynamic>()),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 150,
              child: GradientButton(
                label: 'Save split',
                icon: Icons.save_outlined,
                height: 42,
                loading: savingSplit,
                onPressed: _saveSplit,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventTile(BuildContext context, Map<String, dynamic> e) {
    final index = e['index'] as int;
    final name = e['name']?.toString() ?? 'Event $index';
    final fixedTotal = (e['userPayout'] as num?)?.toDouble() ?? 0 + ((e['referPayout'] as num?)?.toDouble() ?? 0);
    final total = ((e['userPayout'] as num?)?.toDouble() ?? 0) + ((e['referPayout'] as num?)?.toDouble() ?? 0);
    final locked = total == 1; // backend disables customization when total payout is exactly ₹1
    final uPo = userPo[index] ?? (e['userPayout'] as num?)?.toDouble() ?? 0;
    final rPo = referPo[index] ?? (e['referPayout'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AffColors.pageBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AffColors.ink)),
              Text('Total ₹${total.toStringAsFixed(0)}', style: const TextStyle(color: AffColors.inkFaint, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          if (locked)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Fixed payout — not customizable', style: TextStyle(fontSize: 11, color: AffColors.inkFaint)),
            )
          else ...[
            const SizedBox(height: 4),
            Text('User payout: ₹${uPo.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AffColors.inkMuted)),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AffColors.purpleEnd,
                inactiveTrackColor: AffColors.hairline,
                thumbColor: AffColors.purpleEnd,
                overlayColor: AffColors.purpleEnd.withValues(alpha: 0.12),
              ),
              child: Slider(
                value: uPo.clamp(0, total == 0 ? fixedTotal : total),
                min: 0,
                max: total == 0 ? 1 : total,
                divisions: total > 0 ? total.round().clamp(1, 1000) : 1,
                label: uPo.toStringAsFixed(0),
                onChanged: (v) {
                  setState(() {
                    userPo[index] = v;
                    referPo[index] = total - v;
                  });
                },
              ),
            ),
            Text('Refer payout: ₹${(referPo[index] ?? rPo).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AffColors.inkMuted)),
          ],
        ],
      ),
    );
  }

  Future<void> _saveSplit() async {
    setState(() => savingSplit = true);
    final payload = <String, dynamic>{};
    userPo.forEach((idx, v) {
      payload['eve_${idx}_user_po'] = v;
      payload['eve_${idx}_refer_po'] = referPo[idx] ?? 0;
    });
    try {
      await ref.read(offersRepositoryProvider).updatePayoutSplit(widget.offId, payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout split updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save split: $e')));
      }
    } finally {
      if (mounted) setState(() => savingSplit = false);
    }
  }

  Widget _textSection(BuildContext context, String title, dynamic content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AffSectionHeader(title: title),
          BentoCard(
            child: Text(content.toString(), style: const TextStyle(color: AffColors.ink, fontSize: 13.5, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
