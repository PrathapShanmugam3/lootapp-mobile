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
        error: (e, _) => ErrorState(
          message: 'Failed to load offer.\n$e',
          onRetry: () => ref.invalidate(offerDetailProvider(offId)),
        ),
        data: (data) => ResponsiveBody(
          child: _OfferDetailBody(offId: offId, data: data),
        ),
      ),
    );
  }
}

List<String> _splitLines(dynamic text) => (text?.toString() ?? '')
    .split('\n')
    .map((s) => s.trim())
    .where((s) => s.isNotEmpty)
    .toList();

/// Strips leading bullets/numbering ("•", "-", "1.", "2)") that admins often
/// type into offer copy, so the app can draw its own markers.
String _stripMarker(String s) =>
    s.replaceFirst(RegExp(r'^([•\-*–]|\d+[.)])\s*'), '');

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
  final Map<int, TextEditingController> _userCtrl = {};
  final Map<int, TextEditingController> _referCtrl = {};
  bool _bannerFailed = false;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  @override
  void dispose() {
    for (final c in [..._userCtrl.values, ..._referCtrl.values]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _fmtAmount(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  void _hydrate() {
    offer = (widget.data['offer'] as Map?)?.cast<String, dynamic>() ?? {};
    referralLink =
        (widget.data['referralLink'] as Map?)?.cast<String, dynamic>() ?? {};
    availableThemes =
        ((widget.data['availableThemes'] as List?) ??
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
    final def = domains.firstWhere(
      (d) => d['is_default'] == 1 || d['is_default'] == true,
      orElse: () => domains.first,
    );
    return def['domain']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final events = ((offer['events'] as List?) ?? [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
    final bannerImage = offer['bannerImage']?.toString();
    final hasBanner = bannerImage != null && bannerImage.isNotEmpty;
    final domains = ref.watch(linkDomainsProvider).valueOrNull ?? const [];
    final origin = _origin(domains);
    final showTiming = events.any(
      (e) => (e['payTime'] ?? '').toString().isNotEmpty || _eventTotal(e) == 1,
    );

    final steps = _splitLines(offer['steps']);
    final benefits = _splitLines(offer['offerBenefits']);
    final fees = _splitLines(offer['offerFeesCharges']);
    final terms = _splitLines(offer['terms']);

    var i = 0;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _hero(context)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
          sliver: SliverList.list(
            children: [
              if (hasBanner && !_bannerFailed) ...[
                FadeSlideIn(index: i++, child: _banner(bannerImage)),
                const SizedBox(height: 20),
              ],
              FadeSlideIn(
                index: i++,
                child: _linksCard(context, origin, domains),
              ),
              const SizedBox(height: 28),
              if (availableThemes.isNotEmpty) ...[
                FadeSlideIn(index: i++, child: _templatesSection(context)),
                const SizedBox(height: 28),
              ],
              if (showTiming) ...[
                FadeSlideIn(index: i++, child: _timingSection(events)),
                const SizedBox(height: 28),
              ],
              if (events.isNotEmpty) ...[
                FadeSlideIn(index: i++, child: _splitSection(context, events)),
                const SizedBox(height: 28),
              ],
              if (steps.isNotEmpty)
                FadeSlideIn(
                  index: i++,
                  child: _listSection(
                    'How it works',
                    Icons.route_rounded,
                    AffColors.purpleEnd,
                    steps,
                    numbered: true,
                  ),
                ),
              if (benefits.isNotEmpty)
                FadeSlideIn(
                  index: i++,
                  child: _listSection(
                    'Benefits',
                    Icons.card_giftcard_rounded,
                    AffColors.emerald,
                    benefits,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
              if (fees.isNotEmpty)
                FadeSlideIn(
                  index: i++,
                  child: _listSection(
                    'Fees & charges',
                    Icons.receipt_long_rounded,
                    AffColors.amber,
                    fees,
                    keyValue: true,
                  ),
                ),
              if (terms.isNotEmpty)
                FadeSlideIn(
                  index: i++,
                  child: _listSection(
                    'Terms',
                    Icons.gavel_rounded,
                    AffColors.pink,
                    terms,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- hero

  Widget _hero(BuildContext context) {
    final logo = offer['logo']?.toString();
    final logoUrl = (logo != null && logo.isNotEmpty)
        ? (logo.startsWith('http') ? logo : '${ApiConfig.baseUrl}$logo')
        : null;
    final category = offer['category']?.toString() ?? '';
    // "{amount}" in admin-written titles = this affiliate's total user split,
    // as their leads page shows it (the API fills it too; this covers older
    // deployments).
    final userTotal = userPo.values.fold<double>(0, (sum, v) => sum + v);
    final offerTitle = (offer['offerTitle']?.toString() ?? '').replaceAll(
      '{amount}',
      _fmtAmount(userTotal),
    );
    final name = offer['offerName']?.toString() ?? '';
    final eventCount = ((offer['events'] as List?) ?? []).length;
    final themeLabel = availableThemes
        .firstWhere(
          (t) => t['key'] == selectedTheme,
          orElse: () => const {},
        )['label']
        ?.toString();

    Widget chip(String text, {IconData? icon}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: AffText.jakarta(
              10.5,
              FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.92),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E1065).withValues(alpha: 0.38),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        child: DecoratedBox(
          // Deep violet fading to a restrained purple — richer and calmer than
          // the neon magenta of the app header.
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E1065), Color(0xFF5B21B6), Color(0xFF8B3FE0)],
              stops: [0, 0.6, 1],
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(child: DecorativeOrbs()),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: CircleBorder(
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).maybePop(),
                          child: const SizedBox(
                            width: 38,
                            height: 38,
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 66,
                            height: 66,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(21),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            alignment: Alignment.center,
                            child: logoUrl != null
                                ? Image.network(
                                    logoUrl,
                                    fit: BoxFit.cover,
                                    width: 66,
                                    height: 66,
                                    errorBuilder: (_, __, ___) =>
                                        _initials(name),
                                  )
                                : _initials(name),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AffText.jakarta(
                                    22,
                                    FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (category.isNotEmpty)
                                      chip(category.toUpperCase()),
                                    chip(
                                      '$eventCount ${eventCount == 1 ? 'event' : 'events'}',
                                      icon: Icons.bolt_rounded,
                                    ),
                                    if (themeLabel != null)
                                      chip(themeLabel, icon: Icons.web_rounded),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (offerTitle.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          offerTitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AffText.jakarta(
                            13,
                            FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.86),
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 13, 16, 13),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.17),
                              Colors.white.withValues(alpha: 0.07),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFDE68A),
                                    Color(0xFFF59E0B),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Text(
                                '₹',
                                style: AffText.jakarta(
                                  22,
                                  FontWeight.w800,
                                  color: const Color(0xFF5B3A00),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TOTAL PAYOUT',
                                    style: AffText.jakarta(
                                      9.5,
                                      FontWeight.w800,
                                      color: Colors.white.withValues(
                                        alpha: 0.72,
                                      ),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '₹${offer['totalPayout'] ?? 0}',
                                      style: AffText.number(
                                        34,
                                        FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -1,
                                        height: 1.05,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final text = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'
        : (name.trim().isEmpty
              ? '?'
              : name.trim().substring(0, name.trim().length >= 2 ? 2 : 1));
    return Text(
      text.toUpperCase(),
      style: AffText.number(20, FontWeight.w700, color: AffColors.purpleEnd),
    );
  }

  Widget _banner(String bannerImage) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 16 / 7,
        child: Image.network(
          bannerImage.startsWith('http')
              ? bannerImage
              : '${ApiConfig.baseUrl}$bannerImage',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_bannerFailed)
                setState(() => _bannerFailed = true);
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // --------------------------------------------------------------- links

  Widget _linksCard(
    BuildContext context,
    String origin,
    List<Map<String, dynamic>> domains,
  ) {
    final code = Uri.encodeComponent(_referCode);
    final current = selectedDomain ?? _defaultDomain(domains);
    return AffCard(
      radius: 24,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AffIconChip(
                icon: Icons.link_rounded,
                size: 38,
                solid: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your tracking links',
                      style: AffText.jakarta(
                        16,
                        FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Share any link — every click is tracked to you',
                      style: AffText.jakarta(
                        11,
                        FontWeight.w500,
                        color: AffColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (domains.length > 1) ...[
            const SizedBox(height: 14),
            Text(
              'LINK DOMAIN',
              style: AffText.jakarta(
                10,
                FontWeight.w800,
                color: AffColors.inkFaint,
                letterSpacing: 0.9,
              ),
            ),
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
                        border: active
                            ? null
                            : Border.all(color: AffColors.fieldBorder),
                      ),
                      child: Text(
                        d,
                        style: AffText.jakarta(
                          11.5,
                          FontWeight.w700,
                          color: active ? Colors.white : AffColors.inkMuted,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 14),
          _LinkTile(
            accentColor: AffColors.purpleEnd,
            label: 'Offer URL',
            link: '$origin/leads?o=$code',
            shareTitle: offer['offerName']?.toString() ?? '',
          ),
          const SizedBox(height: 10),
          _LinkTile(
            accentColor: const Color(0xFFDB2777),
            label: 'Sub refer URL',
            link: '$origin/referral?o=$code',
            shareTitle: offer['offerName']?.toString() ?? '',
          ),
          const SizedBox(height: 10),
          _LinkTile(
            accentColor: const Color(0xFF0284C7),
            label: 'Direct offer link',
            badge: 'No landing page',
            link: '$origin/api/public/direct/$code',
            shareTitle: offer['offerName']?.toString() ?? '',
            hint:
                'Sends visitors straight to the offer — no lead form. Clicks are still tracked and payouts credit to your wallet.',
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
            style: AffText.jakarta(
              11.5,
              FontWeight.w500,
              color: AffColors.inkMuted,
              height: 1.4,
            ),
          ),
        ),
        for (var idx = 0; idx < availableThemes.length; idx++) ...[
          if (idx > 0) const SizedBox(height: 10),
          Builder(
            builder: (_) {
              final t = availableThemes[idx];
              final key = t['key']?.toString() ?? '';
              return _TemplateCard(
                themeKey: key,
                label: t['label']?.toString() ?? key,
                description: t['description']?.toString() ?? '',
                selected: key == selectedTheme,
                saving: savingTheme == key,
                onSelect: savingTheme != null || key == selectedTheme
                    ? null
                    : () => _selectTheme(key),
              );
            },
          ),
        ],
      ],
    );
  }

  Future<void> _selectTheme(String key) async {
    HapticFeedback.selectionClick();
    setState(() => savingTheme = key);
    try {
      await ref
          .read(offersRepositoryProvider)
          .updateLandingTheme(widget.offId, key);
      if (!mounted) return;
      setState(() => selectedTheme = key);
      final label =
          availableThemes.firstWhere(
            (t) => t['key'] == key,
            orElse: () => const {},
          )['label'] ??
          key;
      showSuccessToast(
        context,
        '$label template is now live on your Offer URL',
        title: 'Template updated',
      );
    } catch (e) {
      if (mounted) showErrorToast(context, e, title: 'Template not updated');
    } finally {
      if (mounted) setState(() => savingTheme = null);
    }
  }

  // -------------------------------------------------------------- timing

  double _eventTotal(Map<String, dynamic> e) =>
      ((e['userPayout'] as num?)?.toDouble() ?? 0) +
      ((e['referPayout'] as num?)?.toDouble() ?? 0);

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
                if (j > 0)
                  Divider(height: 1, thickness: 1, color: AffColors.hairline),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      const AffIconChip(icon: Icons.schedule_rounded, size: 30),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          events[j]['name']?.toString() ?? 'Event',
                          style: AffText.jakarta(13, FontWeight.w700),
                        ),
                      ),
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text.toUpperCase(),
        style: AffText.jakarta(
          10,
          FontWeight.w800,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // --------------------------------------------------------------- split

  Widget _splitSection(
    BuildContext context,
    List<Map<String, dynamic>> events,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AffSectionHeader(title: 'Customize payout'),
        AffCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set what the user and the referrer get for each event — whatever is left is your profit.',
                style: AffText.jakarta(
                  11.5,
                  FontWeight.w500,
                  color: AffColors.inkMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              for (final e in events) _eventTile(context, e),
              const SizedBox(height: 2),
              GradientButton(
                label: 'Save split',
                icon: Icons.check_rounded,
                height: 46,
                loading: savingSplit,
                onPressed: _saveSplit,
              ),
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
    final locked =
        total ==
        1; // backend disables customization when total payout is exactly ₹1
    final userCtrl = _userCtrl.putIfAbsent(
      index,
      () => TextEditingController(
        text: _fmtAmount(
          userPo[index] ?? (e['userPayout'] as num?)?.toDouble() ?? 0,
        ),
      ),
    );
    final referCtrl = _referCtrl.putIfAbsent(
      index,
      () => TextEditingController(
        text: _fmtAmount(
          referPo[index] ?? (e['referPayout'] as num?)?.toDouble() ?? 0,
        ),
      ),
    );

    // Same rules as the web/PHP offer page: User and Refer are independent,
    // each 0..total, and together they can't exceed the total — whatever's
    // left is the affiliate's profit.
    void onEdit(String raw, {required bool isUser}) {
      final mine = isUser ? userCtrl : referCtrl;
      final otherValue = (isUser ? referPo[index] : userPo[index]) ?? 0;
      var v = double.tryParse(raw) ?? 0;
      final max = double.parse((total - otherValue).toStringAsFixed(2));
      if (v > max) {
        v = max < 0 ? 0 : max;
        mine.value = TextEditingValue(
          text: _fmtAmount(v),
          selection: TextSelection.collapsed(offset: _fmtAmount(v).length),
        );
        showWarningToast(
          context,
          'User + Refer cannot exceed ₹${_fmtAmount(total)}',
        );
      }
      setState(() => isUser ? userPo[index] = v : referPo[index] = v);
    }

    final profit = double.parse(
      (total - (userPo[index] ?? 0) - (referPo[index] ?? 0)).toStringAsFixed(2),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 8),
      decoration: BoxDecoration(
        color: AffColors.fieldBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AffColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AffText.jakarta(13.5, FontWeight.w700),
                ),
              ),
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: AffText.number(
                  14,
                  FontWeight.w700,
                  color: AffColors.purpleEnd,
                ),
              ),
            ],
          ),
          if (locked)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded, size: 13, color: AffColors.inkFaint),
                  const SizedBox(width: 5),
                  Text(
                    'Fixed payout — not customizable',
                    style: AffText.jakarta(
                      11,
                      FontWeight.w500,
                      color: AffColors.inkFaint,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _amountField(
                    'User',
                    userCtrl,
                    AffColors.purpleEnd,
                    enabled: total > 0,
                    onChanged: (v) => onEdit(v, isUser: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _amountField(
                    'Refer',
                    referCtrl,
                    AffColors.pink,
                    enabled: total > 0,
                    onChanged: (v) => onEdit(v, isUser: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: (profit >= 0 ? AffColors.success : AffColors.danger)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (profit >= 0 ? AffColors.success : AffColors.danger)
                      .withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.savings_rounded,
                    size: 16,
                    color: profit >= 0 ? AffColors.success : AffColors.danger,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'YOUR PROFIT',
                      style: AffText.jakarta(
                        10.5,
                        FontWeight.w800,
                        color: profit >= 0
                            ? AffColors.success
                            : AffColors.danger,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Text(
                    '₹${_fmtAmount(profit)}',
                    style: AffText.number(
                      16,
                      FontWeight.w700,
                      color: profit >= 0 ? AffColors.success : AffColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _amountField(
    String label,
    TextEditingController controller,
    Color tint, {
    required bool enabled,
    required ValueChanged<String> onChanged,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AffColors.fieldBorder),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AffText.jakarta(
            10,
            FontWeight.w800,
            color: tint,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          style: AffText.number(15, FontWeight.w700, color: AffColors.ink),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AffColors.surface,
            prefixText: '₹ ',
            prefixStyle: AffText.number(15, FontWeight.w700, color: tint),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: tint, width: 1.5),
            ),
          ),
        ),
      ],
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
      await ref
          .read(offersRepositoryProvider)
          .updatePayoutSplit(widget.offId, payload);
      if (mounted)
        showSuccessToast(
          context,
          'Your new payout split is saved',
          title: 'Payout updated',
        );
    } catch (e) {
      if (mounted) showErrorToast(context, e, title: 'Split not saved');
    } finally {
      if (mounted) setState(() => savingSplit = false);
    }
  }

  // --------------------------------------------------------- text lists

  Widget _listSection(
    String title,
    IconData headIcon,
    Color tint,
    List<String> lines, {
    bool numbered = false,
    IconData? icon,
    bool keyValue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AffCard(
        wash: tint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AffIconChip(icon: headIcon, color: tint, size: 34, solid: true),
                const SizedBox(width: 11),
                Text(
                  title,
                  style: AffText.jakarta(
                    15.5,
                    FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (var j = 0; j < lines.length; j++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: j == lines.length - 1 ? 0 : 11,
                ),
                child: keyValue
                    ? _feeRow(lines[j], tint)
                    : _bulletRow(
                        _stripMarker(lines[j]),
                        tint,
                        numbered ? j + 1 : null,
                        icon,
                      ),
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
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: AffText.number(11, FontWeight.w700, color: tint),
            ),
          )
        : icon != null
        ? Icon(icon, size: 18, color: tint)
        : Padding(
            padding: const EdgeInsets.only(top: 6, left: 6, right: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            ),
          );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Align(alignment: Alignment.topCenter, child: marker),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AffText.jakarta(
              13,
              FontWeight.w500,
              color: AffColors.inkLabel,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _feeRow(String line, Color tint) {
    final m = RegExp(r'^([^:\-]+)[:\-](.+)$').firstMatch(line);
    if (m == null) return _bulletRow(_stripMarker(line), tint, null, null);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AffColors.fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AffColors.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _stripMarker(m.group(1)!.trim()),
              style: AffText.jakarta(
                12.5,
                FontWeight.w600,
                color: AffColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              m.group(2)!.trim(),
              textAlign: TextAlign.right,
              style: AffText.jakarta(12.5, FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// One tracking link: label (+ optional badge), the URL in a soft field, and
/// copy / WhatsApp / Telegram share actions. A slim coloured bar on the left
/// edge tells the three links apart at a glance.
class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.label,
    required this.link,
    required this.shareTitle,
    this.badge,
    this.hint,
    this.accentColor,
  });

  final String label;
  final String link;
  final String shareTitle;
  final String? badge;
  final String? hint;
  final Color? accentColor;
  Color get accent => accentColor ?? AffColors.purpleEnd;

  Future<void> _open(BuildContext context, String url) async {
    if (!await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    )) {
      if (context.mounted) {
        showErrorToast(context, 'That app isn\'t available on this device');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = shareTitle.isEmpty ? link : '$shareTitle — $link';
    return Container(
      decoration: BoxDecoration(
        color: AffColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AffColors.fieldBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3C1478).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color.lerp(accent, Colors.white, 0.3)!, accent],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AffText.jakarta(
                              10,
                              FontWeight.w800,
                              color: accent,
                              letterSpacing: 0.9,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              badge!,
                              style: AffText.jakarta(
                                9,
                                FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AffColors.fieldBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              link,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AffText.number(
                                12,
                                FontWeight.w500,
                                color: AffColors.inkLabel,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ActionDot(
                          tooltip: 'Copy',
                          primary: true,
                          accentColor: accent,
                          child: const Icon(
                            Icons.copy_rounded,
                            size: 17,
                            color: Colors.white,
                          ),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Clipboard.setData(ClipboardData(text: link));
                            showSuccessToast(
                              context,
                              link,
                              title: '$label copied',
                            );
                          },
                        ),
                        _ActionDot(
                          tooltip: 'Share on WhatsApp',
                          child: const WhatsAppGlyph(
                            color: Color(0xFF128C7E),
                            size: 19,
                          ),
                          onTap: () => _open(
                            context,
                            'https://wa.me/?text=${Uri.encodeComponent(text)}',
                          ),
                        ),
                        _ActionDot(
                          tooltip: 'Share on Telegram',
                          child: const Icon(
                            Icons.telegram,
                            size: 21,
                            color: Color(0xFF0088CC),
                          ),
                          onTap: () => _open(
                            context,
                            'https://t.me/share/url?url=${Uri.encodeComponent(link)}&text=${Uri.encodeComponent(shareTitle)}',
                          ),
                        ),
                      ],
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        hint!,
                        style: AffText.jakarta(
                          10.5,
                          FontWeight.w500,
                          color: AffColors.inkFaint,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round 38dp action button. [primary] = filled with the tile's accent (copy);
/// otherwise a white button with a hairline ring (share targets).
class _ActionDot extends StatelessWidget {
  const _ActionDot({
    required this.tooltip,
    required this.child,
    required this.onTap,
    this.primary = false,
    this.accentColor,
  });

  final String tooltip;
  final Widget child;
  final VoidCallback onTap;
  final bool primary;
  final Color? accentColor;
  Color get accent => accentColor ?? AffColors.purpleEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: primary
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.lerp(accent, Colors.white, 0.22)!, accent],
                  )
                : null,
            color: primary ? null : AffColors.surface,
            border: primary ? null : Border.all(color: AffColors.fieldBorder),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: Center(child: child),
            ),
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

  void _openPreview(BuildContext context) {
    HapticFeedback.selectionClick();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => _TemplatePreviewDialog(
        themeKey: themeKey,
        label: label,
        description: description,
        selected: selected,
        onUse: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AffColors.purpleEnd, AffColors.purpleStart],
                )
              : null,
          color: selected ? null : AffColors.fieldBorder,
          borderRadius: BorderRadius.circular(18),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AffColors.purpleEnd.withValues(alpha: 0.20),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : AffColors.cardShadow,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AffColors.surface,
            borderRadius: BorderRadius.circular(16.5),
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Thumbnail: the full-size mockup scaled down. Tap to preview.
              GestureDetector(
                onTap: () => _openPreview(context),
                child: SizedBox(
                  width: 84,
                  height: 62,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: SizedBox(
                            width: 172,
                            height: 128,
                            child: _TemplateMockup(themeKey: themeKey),
                          ),
                        ),
                      ),
                      if (saving)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AffColors.surface.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AffColors.purpleEnd,
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          right: 3,
                          bottom: 3,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.visibility_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AffText.jakarta(
                        13.5,
                        FontWeight.w800,
                        color: selected ? AffColors.purpleEnd : AffColors.ink,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AffText.jakarta(
                          10.5,
                          FontWeight.w500,
                          color: AffColors.inkFaint,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 76,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _cardButton(
                      label: 'Preview',
                      icon: Icons.visibility_rounded,
                      onTap: () => _openPreview(context),
                      outline: true,
                    ),
                    const SizedBox(height: 6),
                    _cardButton(
                      label: selected ? 'In use' : 'Use',
                      icon: selected
                          ? Icons.check_circle_rounded
                          : Icons.touch_app_rounded,
                      onTap: onSelect,
                      dim: selected,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool dim = false,
    bool outline = false,
  }) {
    final fg = outline
        ? AffColors.purpleEnd
        : (dim ? AffColors.live : Colors.white);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Ink(
          height: 28,
          decoration: BoxDecoration(
            gradient: outline || dim ? null : AffColors.gradient,
            color: outline
                ? Colors.transparent
                : (dim ? AffColors.liveBg : null),
            border: outline
                ? Border.all(color: AffColors.purpleEnd.withValues(alpha: 0.4))
                : null,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: fg),
              const SizedBox(width: 4),
              Text(
                label,
                style: AffText.jakarta(10.5, FontWeight.w800, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen look at a landing-page theme before committing to it.
class _TemplatePreviewDialog extends StatelessWidget {
  const _TemplatePreviewDialog({
    required this.themeKey,
    required this.label,
    required this.description,
    required this.selected,
    required this.onUse,
  });

  final String themeKey;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: AffColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: AffText.jakarta(
                              15,
                              FontWeight.w800,
                              color: AffColors.ink,
                            ),
                          ),
                          if (description.isNotEmpty)
                            Text(
                              description,
                              style: AffText.jakarta(
                                11,
                                FontWeight.w500,
                                color: AffColors.inkFaint,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: AffColors.inkFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _TemplateMockup(themeKey: themeKey, height: 320),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: selected
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            onUse?.call();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AffColors.purpleEnd,
                      disabledBackgroundColor: AffColors.chipLilac,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.touch_app_rounded,
                      size: 16,
                      color: selected ? AffColors.purpleEnd : Colors.white,
                    ),
                    label: Text(
                      selected ? 'Already in use' : 'Use this template',
                      style: AffText.jakarta(
                        13,
                        FontWeight.w800,
                        color: selected ? AffColors.purpleEnd : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
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
  const _TemplateMockup({required this.themeKey, this.height = 128});

  final String themeKey;
  final double height;

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h, Color c, {double r = 3}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    final Widget content;
    final Decoration bg;
    switch (themeKey) {
      case 'minimal':
        bg = BoxDecoration(
          color: const Color(0xFFFAFAFC),
          border: Border.all(color: AffColors.hairline),
        );
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AffColors.chipLilac,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
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
            Row(
              children: [
                bar(14, 14, AffColors.gold, r: 4),
                const Spacer(),
                bar(24, 5, Colors.white24),
              ],
            ),
            const SizedBox(height: 10),
            bar(140, 11, Colors.white),
            const SizedBox(height: 5),
            bar(100, 11, Colors.white),
            const SizedBox(height: 7),
            bar(70, 4, Colors.white38),
            const Spacer(),
            Row(
              children: [
                bar(40, 14, Colors.white12, r: 4),
                const SizedBox(width: 5),
                bar(40, 14, Colors.white12, r: 4),
              ],
            ),
            const SizedBox(height: 6),
            bar(double.infinity, 18, AffColors.gold, r: 4),
          ],
        );
      default:
        bg = const BoxDecoration(gradient: AffColors.heroGradient);
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                bar(50, 5, Colors.white70),
              ],
            ),
            const SizedBox(height: 9),
            bar(115, 7, Colors.white),
            const SizedBox(height: 5),
            bar(85, 4, Colors.white60),
            const Spacer(),
            Row(
              children: [
                for (var k = 0; k < 3; k++) ...[
                  if (k > 0) const SizedBox(width: 5),
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            bar(double.infinity, 16, Colors.white, r: 8),
          ],
        );
    }

    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: (bg as BoxDecoration).copyWith(
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(10),
      child: content,
    );
  }
}
