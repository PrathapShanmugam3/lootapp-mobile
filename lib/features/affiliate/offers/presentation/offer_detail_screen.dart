import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import 'offers_providers.dart';

class OfferDetailScreen extends ConsumerWidget {
  const OfferDetailScreen({super.key, required this.offId});

  final String offId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(offerDetailProvider(offId));

    return Scaffold(
      backgroundColor: AppColors.canvas,
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

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.ink,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasBanner && !_bannerFailed) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
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
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    if (logo != null && logo.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          logo.startsWith('http') ? logo : '${ApiConfig.baseUrl}$logo',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(width: 48, height: 48),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            offer['offerName']?.toString() ?? '',
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink),
                          ),
                          if ((offer['category']?.toString() ?? '').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: StatusChip(text: offer['category'].toString()),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if ((offer['offerTitle']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(offer['offerTitle'].toString(), style: const TextStyle(color: AppColors.inkMuted, fontSize: 13.5)),
                ],
                const SizedBox(height: 16),
                GradientHeroCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total payout', style: TextStyle(color: Colors.white70)),
                      Text('₹$totalPayout', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _referralLinkCard(context),
                const SizedBox(height: 20),
                if (availableThemes.isNotEmpty) ...[
                  const SectionHeader(title: 'Landing page theme'),
                  _themePicker(context),
                  const SizedBox(height: 20),
                ],
                if (events.isNotEmpty) ...[
                  const SectionHeader(title: 'Payout events'),
                  _eventsCard(context, events),
                  const SizedBox(height: 20),
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
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.link, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text('Your referral links', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.ink)),
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
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.inkFaint, letterSpacing: 0.6)),
                const SizedBox(height: 2),
                Text(link, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(999)),
            child: IconButton(
              icon: const Icon(Icons.copy, size: 16, color: AppColors.primary),
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
    return BentoCard(
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
                color: selected ? AppColors.ink : AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(999),
                border: selected ? null : Border.all(color: AppColors.hairline),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.inkMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _eventsCard(BuildContext context, List events) {
    return BentoCard(
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
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.ink)),
              Text('Total ₹${total.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.inkFaint, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          if (locked)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Fixed payout — not customizable', style: TextStyle(fontSize: 11, color: AppColors.inkFaint)),
            )
          else ...[
            const SizedBox(height: 4),
            Text('User payout: ₹${uPo.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.hairlineStrong,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.1),
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
            Text('Refer payout: ₹${(referPo[index] ?? rPo).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
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
          SectionHeader(title: title),
          BentoCard(
            child: Text(content.toString(), style: const TextStyle(color: AppColors.inkLabel, fontSize: 13.5, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
