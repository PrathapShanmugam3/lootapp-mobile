import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/widgets/affiliate_design.dart';
import '../../presentation/widgets/community_join.dart';
import 'offers_providers.dart';
import '../../../../core/widgets/app_toast.dart';

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

List<String> _splitLines(dynamic text) => (text?.toString() ?? '').split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

/// Strips leading bullets/numbering ("•", "-", "1.", "2)") that admins often
/// type into offer copy, so the app can draw its own markers.
String _stripMarker(String s) => s.replaceFirst(RegExp(r'^([•\-*–]|\d+[.)])\s*'), '');

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
  late List<Map<String, dynamic>> availableThemes;
  String? selectedTheme;
  String? savingTheme;
  bool savingSplit = false;
  String? selectedDomain;
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
    availableThemes = ((widget.data['availableThemes'] as List?) ??
            [
              {'key': 'classic', 'label': 'Classic'},
              {'key': 'minimal', 'label': 'Minimal'},
              {'key': 'bold', 'label': 'Bold'},
            ])
        .map((t) => (t as Map).cast<String, dynamic>())
        .toList();
    selectedTheme = referralLink['landingTheme']?.toString();
    final split = (referralLink['currentSplit'] as List?) ?? [];
    for (final s in split) {
      final m = (s as Map).cast<String, dynamic>();
      final idx = m['index'] as int;
      userPo[idx] = (m['userPayout'] as num?)?.toDouble() ?? 0;
      referPo[idx] = (m['referPayout'] as num?)?.toDouble() ?? 0;
    }
  }

  String get _referCode => referralLink['referCode']?.toString() ?? '';

  /// Origin the links are built on: the chosen short-link domain, else the
  /// origin of the backend-built offer link (the app's APP_URL).
  String _origin(List<Map<String, dynamic>> domains) {
    final domain = selectedDomain ?? _defaultDomain(domains);
    if (domain != null && domain.isNotEmpty) return 'https://$domain';
    final offerLink = referralLink['offerLink']?.toString() ?? '';
    final uri = Uri.tryParse(offerLink);
    return (uri != null && uri.hasScheme) ? uri.origin : ApiConfig.baseUrl;
  }

  String? _defaultDomain(List<Map<String, dynamic>> domains) {
    if (domains.isEmpty) return null;
    final def = domains.firstWhere((d) => d['is_default'] == 1 || d['is_default'] == true, orElse: () => domains.first);
    return def['domain']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final events = ((offer['events'] as List?) ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
    final bannerImage = offer['bannerImage']?.toString();
    final hasBanner = bannerImage != null && bannerImage.isNotEmpty;
    final domains = ref.watch(linkDomainsProvider).valueOrNull ?? const [];
    final origin = _origin(domains);
    final showTiming = events.any((e) => (e['payTime'] ?? '').toString().isNotEmpty || _eventTotal(e) == 1);

    final steps = _splitLines(offer['steps']);
    final benefits = _splitLines(offer['offerBenefits']);
    final fees = _splitLines(offer['offerFeesCharges']);
    final terms = _splitLines(offer['terms']);

    var i = 0;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _hero(context)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          sliver: SliverList.list(
            children: [
              if (hasBanner && !_bannerFailed) ...[
                FadeSlideIn(index: i++, child: _banner(bannerImage)),
                const SizedBox(height: 18),
              ],
              FadeSlideIn(index: i++, child: _linksCard(context, origin, domains)),
              const SizedBox(height: 22),
              if (availableThemes.isNotEmpty) ...[
                FadeSlideIn(index: i++, child: _templatesSection(context)),
                const SizedBox(height: 22),
              ],
              if (showTiming) ...[
                FadeSlideIn(index: i++, child: _timingSection(events)),
                const SizedBox(height: 22),
              ],
              if (events.isNotEmpty) ...[
                FadeSlideIn(index: i++, child: _splitSection(context, events)),
                const SizedBox(height: 22),
              ],
              if (steps.isNotEmpty) FadeSlideIn(index: i++, child: _listSection('How it works', Icons.route_rounded, AffColors.purpleEnd, steps, numbered: true)),
              if (benefits.isNotEmpty) FadeSlideIn(index: i++, child: _listSection('Benefits', Icons.card_giftcard_rounded, AffColors.emerald, benefits, icon: Icons.check_circle_rounded)),
              if (fees.isNotEmpty) FadeSlideIn(index: i++, child: _listSection('Fees & charges', Icons.receipt_long_rounded, AffColors.amber, fees, keyValue: true)),
              if (terms.isNotEmpty) FadeSlideIn(index: i++, child: _listSection('Terms', Icons.gavel_rounded, AffColors.pink, terms)),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- hero

  Widget _hero(BuildContext context) {
    final logo = offer['logo']?.toString();
    final logoUrl = (logo != null && logo.isNotEmpty) ? (logo.startsWith('http') ? logo : '${ApiConfig.baseUrl}$logo') : null;
    final category = offer['category']?.toString() ?? '';
    final offerTitle = offer['offerTitle']?.toString() ?? '';
    final name = offer['offerName']?.toString() ?? '';
    final eventCount = ((offer['events'] as List?) ?? []).length;
    final themeLabel = availableThemes.firstWhere((t) => t['key'] == selectedTheme, orElse: () => const {})['label']?.toString();

    return DecoratedBox(
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
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 22),
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
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))],
                              ),
                              clipBehavior: Clip.antiAlias,
                              alignment: Alignment.center,
                              child: logoUrl != null
                                  ? Image.network(logoUrl, fit: BoxFit.cover, width: 62, height: 62, errorBuilder: (_, __, ___) => _initials(name))
                                  : _initials(name),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: AffText.jakarta(21, FontWeight.w800, color: Colors.white, letterSpacing: -0.5, height: 1.2)),
                                  if (category.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
                                        child: Text(category.toUpperCase(), style: AffText.jakarta(10, FontWeight.w800, color: Colors.white, letterSpacing: 0.8)),
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
                          child: Text(offerTitle, style: AffText.jakarta(13, FontWeight.w500, color: Colors.white.withValues(alpha: 0.82), height: 1.45)),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('TOTAL PAYOUT', style: AffText.jakarta(10, FontWeight.w800, color: Colors.white.withValues(alpha: 0.72), letterSpacing: 1.2)),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text('₹${offer['totalPayout'] ?? 0}', style: AffText.number(30, FontWeight.w700, color: AffColors.gold, letterSpacing: -1)),
                                  ),
                                ],
                              ),
                            ),
                            _heroStat('$eventCount', eventCount == 1 ? 'event' : 'events'),
                            if (themeLabel != null) ...[const SizedBox(width: 8), _heroStat(themeLabel, 'template')],
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
    );
  }

  Widget _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final text = words.length >= 2 ? '${words[0][0]}${words[1][0]}' : (name.trim().isEmpty ? '?' : name.trim().substring(0, name.trim().length >= 2 ? 2 : 1));
    return Text(text.toUpperCase(), style: AffText.number(20, FontWeight.w700, color: AffColors.purpleEnd));
  }

  Widget _heroStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: AffText.jakarta(13, FontWeight.w800, color: Colors.white)),
          Text(label, style: AffText.jakarta(9.5, FontWeight.w600, color: Colors.white.withValues(alpha: 0.72))),
        ],
      ),
    );
  }

  Widget _banner(String bannerImage) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
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
    );
  }

  // --------------------------------------------------------------- links

  Widget _linksCard(BuildContext context, String origin, List<Map<String, dynamic>> domains) {
    final code = Uri.encodeComponent(_referCode);
    final current = selectedDomain ?? _defaultDomain(domains);
    return AffCard(
      wash: AffColors.purpleStart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AffIconChip(icon: Icons.link_rounded, size: 38, solid: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your tracking links', style: AffText.jakarta(15.5, FontWeight.w800)),
                    Text('Share any link — every click is tracked to you', style: AffText.jakarta(11, FontWeight.w500, color: AffColors.inkFaint)),
                  ],
                ),
              ),
            ],
          ),
          if (domains.length > 1) ...[
            const SizedBox(height: 14),
            Text('LINK DOMAIN', style: AffText.jakarta(10, FontWeight.w800, color: AffColors.inkFaint, letterSpacing: 0.9)),
            const SizedBox(height: 7),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: domains.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (_, idx) {
                  final d = domains[idx]['domain']?.toString() ?? '';
                  final active = d == current;
                  return GestureDetector(
                    onTap: () => setState(() => selectedDomain = d),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: active ? AffColors.gradient : null,
                        color: active ? null : AffColors.fieldBg,
                        borderRadius: BorderRadius.circular(99),
                        border: active ? null : Border.all(color: AffColors.fieldBorder),
                      ),
                      child: Text(d, style: AffText.jakarta(11.5, FontWeight.w700, color: active ? Colors.white : AffColors.inkMuted)),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 14),
          _LinkTile(label: 'Offer URL', link: '$origin/leads?o=$code', shareTitle: offer['offerName']?.toString() ?? ''),
          const SizedBox(height: 10),
          _LinkTile(label: 'Sub refer URL', link: '$origin/referral?o=$code', shareTitle: offer['offerName']?.toString() ?? ''),
          const SizedBox(height: 10),
          _LinkTile(
            label: 'Direct offer link',
            badge: 'No landing page',
            link: '$origin/api/public/direct/$code',
            shareTitle: offer['offerName']?.toString() ?? '',
            hint: 'Sends visitors straight to the offer — no lead form. Clicks are still tracked and payouts credit to your wallet.',
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- templates

  Widget _templatesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AffSectionHeader(title: 'Select landing page template'),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Visitors from your Offer URL see this page. Tap a template to use it.',
            style: AffText.jakarta(11.5, FontWeight.w500, color: AffColors.inkMuted, height: 1.4),
          ),
        ),
        SizedBox(
          height: 262,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: availableThemes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, idx) {
              final t = availableThemes[idx];
              final key = t['key']?.toString() ?? '';
              return _TemplateCard(
                themeKey: key,
                label: t['label']?.toString() ?? key,
                description: t['description']?.toString() ?? '',
                selected: key == selectedTheme,
                saving: savingTheme == key,
                onSelect: savingTheme != null || key == selectedTheme ? null : () => _selectTheme(key),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _selectTheme(String key) async {
    HapticFeedback.selectionClick();
    setState(() => savingTheme = key);
    try {
      await ref.read(offersRepositoryProvider).updateLandingTheme(widget.offId, key);
      if (!mounted) return;
      setState(() => selectedTheme = key);
      final label = availableThemes.firstWhere((t) => t['key'] == key, orElse: () => const {})['label'] ?? key;
      showSuccessToast(context, '$label template is now live on your Offer URL', title: 'Template updated');
    } catch (e) {
      if (mounted) showErrorToast(context, e, title: 'Template not updated');
    } finally {
      if (mounted) setState(() => savingTheme = null);
    }
  }

  // -------------------------------------------------------------- timing

  double _eventTotal(Map<String, dynamic> e) => ((e['userPayout'] as num?)?.toDouble() ?? 0) + ((e['referPayout'] as num?)?.toDouble() ?? 0);

  Widget _timingSection(List<Map<String, dynamic>> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AffSectionHeader(title: 'Payout timing'),
        AffCard(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          child: Column(
            children: [
              for (var j = 0; j < events.length; j++) ...[
                if (j > 0) const Divider(height: 1, thickness: 1, color: AffColors.hairline),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      const AffIconChip(icon: Icons.schedule_rounded, size: 30),
                      const SizedBox(width: 10),
                      Expanded(child: Text(events[j]['name']?.toString() ?? 'Event', style: AffText.jakarta(13, FontWeight.w700))),
                      _timingPill(events[j]),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _timingPill(Map<String, dynamic> e) {
    final payTime = (e['payTime'] ?? '').toString();
    final (text, fg, bg) = _eventTotal(e) == 1
        ? ('Fixed (₹1 event)', AffColors.inkFaint, AffColors.hairline)
        : payTime.isNotEmpty
            ? (payTime, AffColors.purpleEnd, AffColors.chipLilac)
            : ('Not set', AffColors.inkFaint, AffColors.hairline);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(text.toUpperCase(), style: AffText.jakarta(10, FontWeight.w800, color: fg, letterSpacing: 0.4)),
    );
  }

  // --------------------------------------------------------------- split

  Widget _splitSection(BuildContext context, List<Map<String, dynamic>> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AffSectionHeader(title: 'Customize payout'),
        AffCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Split each event\'s payout between you and the people you refer.', style: AffText.jakarta(11.5, FontWeight.w500, color: AffColors.inkMuted, height: 1.4)),
              const SizedBox(height: 12),
              for (final e in events) _eventTile(context, e),
              const SizedBox(height: 2),
              GradientButton(label: 'Save split', icon: Icons.check_rounded, height: 46, loading: savingSplit, onPressed: _saveSplit),
            ],
          ),
        ),
      ],
    );
  }

  Widget _eventTile(BuildContext context, Map<String, dynamic> e) {
    final index = e['index'] as int;
    final name = e['name']?.toString() ?? 'Event $index';
    final total = _eventTotal(e);
    final locked = total == 1; // backend disables customization when total payout is exactly ₹1
    final uPo = (userPo[index] ?? (e['userPayout'] as num?)?.toDouble() ?? 0).clamp(0, total == 0 ? 1 : total).toDouble();
    final rPo = referPo[index] ?? (e['referPayout'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 8),
      decoration: BoxDecoration(color: AffColors.fieldBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AffColors.hairline)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: AffText.jakarta(13.5, FontWeight.w700))),
              Text('₹${total.toStringAsFixed(0)}', style: AffText.number(14, FontWeight.w700, color: AffColors.purpleEnd)),
            ],
          ),
          if (locked)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded, size: 13, color: AffColors.inkFaint),
                  const SizedBox(width: 5),
                  Text('Fixed payout — not customizable', style: AffText.jakarta(11, FontWeight.w500, color: AffColors.inkFaint)),
                ],
              ),
            )
          else ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _splitPill('You get', uPo, AffColors.purpleEnd, AffColors.chipLilac),
                const Spacer(),
                _splitPill('Referral gets', rPo, AffColors.pink, AffColors.chipPink),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                activeTrackColor: AffColors.purpleEnd,
                inactiveTrackColor: AffColors.pink.withValues(alpha: 0.35),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 3),
                overlayColor: AffColors.purpleEnd.withValues(alpha: 0.12),
                valueIndicatorColor: AffColors.ink,
              ),
              child: Slider(
                value: uPo,
                min: 0,
                max: total == 0 ? 1 : total,
                divisions: total > 0 ? total.round().clamp(1, 1000) : 1,
                label: '₹${uPo.toStringAsFixed(0)}',
                onChanged: total == 0
                    ? null
                    : (v) => setState(() {
                          userPo[index] = v;
                          referPo[index] = total - v;
                        }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _splitPill(String label, double amount, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label ', style: AffText.jakarta(10.5, FontWeight.w600, color: fg)),
          Text('₹${amount.toStringAsFixed(0)}', style: AffText.number(12.5, FontWeight.w700, color: fg)),
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
      if (mounted) showSuccessToast(context, 'Your new payout split is saved', title: 'Payout updated');
    } catch (e) {
      if (mounted) showErrorToast(context, e, title: 'Split not saved');
    } finally {
      if (mounted) setState(() => savingSplit = false);
    }
  }

  // --------------------------------------------------------- text lists

  Widget _listSection(String title, IconData headIcon, Color tint, List<String> lines, {bool numbered = false, IconData? icon, bool keyValue = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: AffCard(
        wash: tint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AffIconChip(icon: headIcon, color: tint, size: 34, solid: true),
                const SizedBox(width: 11),
                Text(title, style: AffText.jakarta(15, FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 14),
            for (var j = 0; j < lines.length; j++)
              Padding(
                padding: EdgeInsets.only(bottom: j == lines.length - 1 ? 0 : 11),
                child: keyValue ? _feeRow(lines[j], tint) : _bulletRow(_stripMarker(lines[j]), tint, numbered ? j + 1 : null, icon),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bulletRow(String text, Color tint, int? number, IconData? icon) {
    final Widget marker = number != null
        ? Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Text('$number', style: AffText.number(11, FontWeight.w700, color: tint)),
          )
        : icon != null
            ? Icon(icon, size: 18, color: tint)
            : Padding(
                padding: const EdgeInsets.only(top: 6, left: 6, right: 6),
                child: Container(width: 6, height: 6, decoration: BoxDecoration(color: tint, shape: BoxShape.circle)),
              );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 22, child: Align(alignment: Alignment.topCenter, child: marker)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AffText.jakarta(13, FontWeight.w500, color: AffColors.inkLabel, height: 1.5))),
      ],
    );
  }

  Widget _feeRow(String line, Color tint) {
    final m = RegExp(r'^([^:\-]+)[:\-](.+)$').firstMatch(line);
    if (m == null) return _bulletRow(_stripMarker(line), tint, null, null);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AffColors.fieldBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AffColors.hairline)),
      child: Row(
        children: [
          Expanded(child: Text(_stripMarker(m.group(1)!.trim()), style: AffText.jakarta(12.5, FontWeight.w600, color: AffColors.inkMuted))),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(m.group(2)!.trim(), textAlign: TextAlign.right, style: AffText.jakarta(12.5, FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

/// One tracking link: label (+ optional badge), the URL, and copy / WhatsApp /
/// Telegram share actions.
class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.label, required this.link, required this.shareTitle, this.badge, this.hint});

  final String label;
  final String link;
  final String shareTitle;
  final String? badge;
  final String? hint;

  Future<void> _open(BuildContext context, String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      if (context.mounted) showErrorToast(context, 'That app isn\'t available on this device');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = shareTitle.isEmpty ? link : '$shareTitle — $link';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 8, 10),
      decoration: BoxDecoration(color: AffColors.fieldBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AffColors.fieldBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label.toUpperCase(), style: AffText.jakarta(10, FontWeight.w800, color: AffColors.inkFaint, letterSpacing: 0.8)),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AffColors.chipLilac, borderRadius: BorderRadius.circular(99)),
                  child: Text(badge!, style: AffText.jakarta(9, FontWeight.w700, color: AffColors.purpleEnd)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: Text(link, maxLines: 1, overflow: TextOverflow.ellipsis, style: AffText.number(12.5, FontWeight.w500))),
              const SizedBox(width: 6),
              _ActionDot(
                tooltip: 'Copy',
                color: AffColors.purpleEnd,
                child: const Icon(Icons.copy_rounded, size: 15, color: AffColors.purpleEnd),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Clipboard.setData(ClipboardData(text: link));
                  showSuccessToast(context, link, title: '$label copied');
                },
              ),
              _ActionDot(
                tooltip: 'Share on WhatsApp',
                color: const Color(0xFF128C7E),
                child: const WhatsAppGlyph(color: Color(0xFF128C7E), size: 15),
                onTap: () => _open(context, 'https://wa.me/?text=${Uri.encodeComponent(text)}'),
              ),
              _ActionDot(
                tooltip: 'Share on Telegram',
                color: const Color(0xFF0088CC),
                child: const Icon(Icons.telegram, size: 17, color: Color(0xFF0088CC)),
                onTap: () => _open(context, 'https://t.me/share/url?url=${Uri.encodeComponent(link)}&text=${Uri.encodeComponent(shareTitle)}'),
              ),
            ],
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(hint!, style: AffText.jakarta(10.5, FontWeight.w500, color: AffColors.inkFaint, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class _ActionDot extends StatelessWidget {
  const _ActionDot({required this.tooltip, required this.color, required this.child, required this.onTap});

  final String tooltip;
  final Color color;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: color.withValues(alpha: 0.10),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(width: 32, height: 32, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}

/// Selectable landing-page template: a drawn mini mockup of the theme, its
/// name and description, plus a Use action.
class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.themeKey,
    required this.label,
    required this.description,
    required this.selected,
    required this.saving,
    required this.onSelect,
  });

  final String themeKey;
  final String label;
  final String description;
  final bool selected;
  final bool saving;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: 196,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AffColors.purpleEnd, AffColors.magenta, AffColors.pink]) : null,
          color: selected ? null : AffColors.fieldBorder,
          borderRadius: BorderRadius.circular(22),
          boxShadow: selected ? [BoxShadow(color: AffColors.purpleEnd.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 6))] : AffColors.cardShadow,
        ),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _TemplateMockup(themeKey: themeKey),
                  if (selected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(gradient: AffColors.gradient, borderRadius: BorderRadius.circular(99), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)]),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 3),
                            Text('ACTIVE', style: AffText.jakarta(8.5, FontWeight.w800, color: Colors.white, letterSpacing: 0.6)),
                          ],
                        ),
                      ),
                    ),
                  if (saving)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(14)),
                        alignment: Alignment.center,
                        child: const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AffColors.purpleEnd)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 9),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AffText.jakarta(13.5, FontWeight.w800, color: selected ? AffColors.purpleEnd : AffColors.ink)),
                    const SizedBox(height: 2),
                    SizedBox(
                      height: 30,
                      child: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: AffText.jakarta(10, FontWeight.w500, color: AffColors.inkFaint, height: 1.35)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _cardButton(
                label: selected ? 'In use' : 'Use template',
                icon: selected ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                onTap: onSelect,
                dim: selected,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardButton({required String label, required IconData icon, required VoidCallback? onTap, bool dim = false}) {
    final fg = dim ? AffColors.purpleEnd : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Ink(
          height: 32,
          decoration: BoxDecoration(
            gradient: dim ? null : AffColors.gradient,
            color: dim ? AffColors.chipLilac : null,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
              Text(label, style: AffText.jakarta(11, FontWeight.w800, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Miniature drawing of each landing theme so affiliates can tell them apart
/// at a glance: Classic (purple gradient + stat cards), Minimal (white, big
/// CTA), Bold (dark, heavy type). Unknown keys fall back to Classic.
class _TemplateMockup extends StatelessWidget {
  const _TemplateMockup({required this.themeKey});

  final String themeKey;

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h, Color c, {double r = 3}) => Container(width: w, height: h, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)));

    final Widget content;
    final Decoration bg;
    switch (themeKey) {
      case 'minimal':
        bg = BoxDecoration(color: const Color(0xFFFAFAFC), border: Border.all(color: AffColors.hairline));
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 18, height: 18, decoration: BoxDecoration(color: AffColors.chipLilac, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 10),
            bar(110, 7, AffColors.ink),
            const SizedBox(height: 5),
            bar(80, 4, AffColors.inkHint),
            const SizedBox(height: 4),
            bar(95, 4, AffColors.inkHint.withValues(alpha: 0.6)),
            const Spacer(),
            bar(double.infinity, 9, AffColors.fieldBorder, r: 5),
            const SizedBox(height: 6),
            bar(double.infinity, 18, AffColors.purpleEnd, r: 7),
          ],
        );
      case 'bold':
        bg = const BoxDecoration(color: Color(0xFF0E0B16));
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [bar(14, 14, AffColors.gold, r: 4), const Spacer(), bar(24, 5, Colors.white24)]),
            const SizedBox(height: 10),
            bar(140, 11, Colors.white),
            const SizedBox(height: 5),
            bar(100, 11, Colors.white),
            const SizedBox(height: 7),
            bar(70, 4, Colors.white38),
            const Spacer(),
            Row(children: [bar(40, 14, Colors.white12, r: 4), const SizedBox(width: 5), bar(40, 14, Colors.white12, r: 4)]),
            const SizedBox(height: 6),
            bar(double.infinity, 18, AffColors.gold, r: 4),
          ],
        );
      default:
        bg = const BoxDecoration(gradient: AffColors.heroGradient);
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Container(width: 16, height: 16, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const SizedBox(width: 6), bar(50, 5, Colors.white70)]),
            const SizedBox(height: 9),
            bar(115, 7, Colors.white),
            const SizedBox(height: 5),
            bar(85, 4, Colors.white60),
            const Spacer(),
            Row(
              children: [
                for (var k = 0; k < 3; k++) ...[
                  if (k > 0) const SizedBox(width: 5),
                  Expanded(child: Container(height: 20, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(5)))),
                ],
              ],
            ),
            const SizedBox(height: 6),
            bar(double.infinity, 16, Colors.white, r: 8),
          ],
        );
    }

    return Container(
      height: 128,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: (bg as BoxDecoration).copyWith(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(10),
      child: content,
    );
  }
}
