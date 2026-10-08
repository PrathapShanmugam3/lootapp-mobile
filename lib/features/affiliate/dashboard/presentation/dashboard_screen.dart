import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/common.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../presentation/sample_data.dart';
import '../../presentation/widgets/aff_user_avatar.dart';
import '../../presentation/widgets/affiliate_design.dart';
import '../../reports/presentation/reports_screen.dart';
import 'dashboard_providers.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final _plain = NumberFormat.decimalPattern('en_IN');

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawAsync = ref.watch(dashboardProvider);
    final sample = isSample(rawAsync);
    final dashboardAsync = withSample(rawAsync, SampleData.dashboard);
    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: AffHeader(
        title: 'Dashboard',
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
        onRefresh: () async => ref.refresh(dashboardProvider.future),
        child: dashboardAsync.when(
          loading: () => const LoadingState(),
          error: (err, _) => ErrorState(
            message: 'Could not load dashboard.\n$err',
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
          data: (data) => _DashboardBody(data: data, sample: sample, onRetry: () => ref.invalidate(dashboardProvider)),
        ),
      ),
    );
  }
}

num _num(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.data, this.sample = false, this.onRetry});

  final Map<String, dynamic> data;
  final bool sample;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = (data['user'] as Map?)?.cast<String, dynamic>() ?? {};
    final kpis = (data['kpis'] as Map?)?.cast<String, dynamic>() ?? {};
    final chart = (data['chart'] as List?) ?? [];
    final topCampaigns = (data['topCampaigns'] as List?) ?? [];
    final liveOffers = data['liveOffers'] ?? 0;
    final name = user['name']?.toString().trim() ?? '';

    final clicks = (kpis['clicks'] as Map?)?.cast<String, dynamic>() ?? {};
    final conversions = (kpis['conversions'] as Map?)?.cast<String, dynamic>() ?? {};
    final earnings = (kpis['earnings'] as Map?)?.cast<String, dynamic>() ?? {};

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
      children: [
        if (sample) SampleDataBanner(onRetry: onRetry),
        // --- Welcome hero ---
        FadeSlideIn(
          child: AffHeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${name.isNotEmpty ? name : 'Affiliate'}',
                  style: AffText.jakarta(19, FontWeight.w800, color: Colors.white, letterSpacing: -0.4, height: 1.25),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(99)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PulseDot(color: Color(0xFF4ADE80), size: 7),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text('$liveOffers live offers to promote today', style: AffText.jakarta(12, FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // --- Clicks / Conversions ---
        FadeSlideIn(
          index: 1,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'CLICKS',
                    value: _num(clicks['value']),
                    icon: Icons.near_me_rounded,
                    gradient: const [AffColors.purpleEnd, AffColors.purpleStart],
                    sub: clicks['trend'] != null ? '${clicks['direction']?.toString() == 'down' ? '▼' : '▲'} ${clicks['trend']}% vs yesterday' : null,
                    subColor: clicks['direction']?.toString() == 'down' ? AffColors.danger : AffColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'CONVERSIONS',
                    value: _num(conversions['value']),
                    icon: Icons.autorenew_rounded,
                    gradient: const [AffColors.pink, AffColors.rose],
                    sub: conversions['mtd'] != null ? 'MTD: ${conversions['mtd']}' : null,
                    subColor: AffColors.inkFaint,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // --- Earnings ---
        FadeSlideIn(
          index: 2,
          child: AffCard(
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EARNINGS THIS WEEK', style: AffText.jakarta(10.5, FontWeight.w700, color: AffColors.inkFaint, letterSpacing: 0.95)),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedCount(value: _num(earnings['value']), format: _currency.format, style: AffText.number(30, FontWeight.w700, height: 1.1)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AffColors.amber, AffColors.amberSoft]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text('₹', style: AffText.jakarta(16, FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // --- 7-day performance ---
        FadeSlideIn(
          index: 3,
          child: AffCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('7-Day Performance', style: AffText.jakarta(15, FontWeight.w800)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
                      child: Text('View report →', style: AffText.jakarta(11, FontWeight.w600, color: AffColors.purpleEnd)),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 9, 0, 4),
                  child: Row(
                    children: [
                      const _Legend(color: AffColors.purpleEnd, label: 'Earnings'),
                      if (_series(chart, ['conversions']).any((v) => v > 0)) ...[
                        const SizedBox(width: 14),
                        const _Legend(color: AffColors.pink, label: 'Conversions'),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  height: 120,
                  child: chart.isEmpty ? const EmptyState(message: 'No chart data yet', icon: Icons.show_chart) : _Chart(chart: chart),
                ),
                if (chart.isNotEmpty) _ChartLabels(chart: chart),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // --- Top campaigns ---
        FadeSlideIn(
          index: 4,
          child: AffCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Top Campaigns', style: AffText.jakarta(15, FontWeight.w800)),
                const SizedBox(height: 10),
                if (topCampaigns.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text('No campaign activity yet', style: AffText.jakarta(12.5, FontWeight.w500, color: AffColors.inkFaint)),
                  )
                else
                  for (var i = 0; i < topCampaigns.length; i++) ...[
                    if (i > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1, thickness: 1, color: AffColors.hairline)),
                    _CampaignRow(campaign: (topCampaigns[i] as Map?)?.cast<String, dynamic>() ?? {}),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: AffText.jakarta(10.5, FontWeight.w600, color: AffColors.inkMuted)),
      ],
    );
  }
}

/// White stat tile from the design: tiny caps label + 30×30 gradient chip,
/// a big Space Grotesk number, and a one-line sub caption.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon, required this.gradient, this.sub, this.subColor = AffColors.inkFaint});

  final String label;
  final num value;
  final IconData icon;
  final List<Color> gradient;
  final String? sub;
  final Color subColor;

  @override
  Widget build(BuildContext context) {
    return AffCard(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AffText.jakarta(10.5, FontWeight.w700, color: AffColors.inkFaint, letterSpacing: 0.95))),
              const SizedBox(width: 6),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: Colors.white, size: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedCount(value: value, format: (n) => _plain.format(n.round()), style: AffText.number(30, FontWeight.w700, height: 1.1)),
          ),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AffText.jakarta(10.5, FontWeight.w600, color: subColor)),
          ],
        ],
      ),
    );
  }
}

class _CampaignRow extends StatelessWidget {
  const _CampaignRow({required this.campaign});
  final Map<String, dynamic> campaign;

  @override
  Widget build(BuildContext context) {
    final name = (campaign['name'] ?? campaign['offerName'] ?? campaign['offer_name'] ?? 'Campaign').toString();
    final earnings = _num(campaign['earnings'] ?? campaign['totalEarnings'] ?? campaign['value'] ?? 0);
    final conversions = campaign['conversions'];
    final trimmed = name.trim();
    final abbr = trimmed.isEmpty ? '?' : trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
    final tint = AffColors.tintFor(name);

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: tint.bg, borderRadius: BorderRadius.circular(11)),
          child: Text(abbr, style: AffText.number(12, FontWeight.w700, color: tint.fg)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AffText.jakarta(13, FontWeight.w700)),
              if (conversions != null) Text('$conversions conversions', style: AffText.jakarta(11, FontWeight.w500, color: AffColors.inkFaint)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(_currency.format(earnings), style: AffText.number(14, FontWeight.w700)),
      ],
    );
  }
}

List<double> _series(List chart, List<String> keys) => [
      for (final p in chart)
        () {
          final m = (p as Map?)?.cast<String, dynamic>() ?? {};
          for (final k in keys) {
            if (m[k] != null) return _num(m[k]).toDouble();
          }
          return 0.0;
        }()
    ];

/// Two-line chart from the design: violet line with a lilac area fill, and a
/// thinner pink line. Both draw in from the baseline.
class _Chart extends StatelessWidget {
  const _Chart({required this.chart});

  final List chart;

  @override
  Widget build(BuildContext context) {
    final earn = _series(chart, ['earnings', 'value', 'clicks']);
    final conv = _series(chart, ['conversions']);
    final earnMax = earn.fold<double>(0, (m, v) => v > m ? v : m);
    final convMax = conv.fold<double>(0, (m, v) => v > m ? v : m);
    // The pink line shares the chart height: scale conversions so their peak
    // sits at ~70% of the earnings peak (shape only; the tooltip shows real values).
    final convScale = convMax > 0 && earnMax > 0 ? (earnMax * 0.7) / convMax : 1.0;
    final top = earnMax <= 0 ? 1.0 : earnMax * 1.1;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1600),
      curve: Curves.easeInOutCubic,
      builder: (context, t, _) {
        final a = [for (var i = 0; i < earn.length; i++) FlSpot(i.toDouble(), earn[i] * t)];
        final b = [for (var i = 0; i < conv.length; i++) FlSpot(i.toDouble(), conv[i] * convScale * t)];
        return LineChart(
          duration: Duration.zero,
          LineChartData(
            minY: 0,
            maxY: top,
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AffColors.ink,
                tooltipRoundedRadius: 10,
                getTooltipItems: (spots) => [
                  for (final s in spots)
                    s.barIndex == 0
                        ? LineTooltipItem(_currency.format(s.y), AffText.number(12, FontWeight.w700, color: Colors.white))
                        : LineTooltipItem('${(s.y / convScale).round()} conv', AffText.number(12, FontWeight.w700, color: AffColors.chipPink)),
                ],
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: a,
                isCurved: false,
                color: AffColors.purpleEnd,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AffColors.purpleStart.withValues(alpha: 0.35), AffColors.purpleStart.withValues(alpha: 0)],
                  ),
                ),
              ),
              if (convMax > 0)
                LineChartBarData(
                  spots: b,
                  isCurved: false,
                  color: AffColors.pink,
                  barWidth: 2.4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// x-axis captions under the chart (Space Grotesk 9.5) — first, middle and
/// last points when the API sends a label/date for each.
class _ChartLabels extends StatelessWidget {
  const _ChartLabels({required this.chart});
  final List chart;

  String? _label(int i) {
    final m = (chart[i] as Map?)?.cast<String, dynamic>() ?? {};
    final v = m['label'] ?? m['date'] ?? m['day'];
    return v?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final n = chart.length;
    final idx = <int>{0, n ~/ 3, (2 * n) ~/ 3, n - 1}.toList()..sort();
    final labels = [for (final i in idx) _label(i)];
    if (labels.any((l) => l == null || l.isEmpty)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [for (final l in labels) Text(l!, style: AffText.number(9.5, FontWeight.w600, color: AffColors.inkHint))],
      ),
    );
  }
}
