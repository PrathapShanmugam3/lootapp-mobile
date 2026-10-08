import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/common.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../presentation/profile_menu_sheet.dart';
import '../../presentation/widgets/affiliate_design.dart';
import '../../reports/presentation/reports_screen.dart';
import 'dashboard_providers.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final name = dashboardAsync.valueOrNull != null
        ? ((dashboardAsync.value!['user'] as Map?)?['name']?.toString() ?? '')
        : '';
    final initials = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'TA';

    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: AffHeader(
        title: 'Dashboard',
        subtitle: 'LootHat Affiliate',
        actions: [
          AffHeaderIcon(
            icon: Icons.notifications_outlined,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          AffHeaderAvatar(
            initials: initials,
            onTap: () => showProfileMenuSheet(context, ref, initials: initials, name: name),
          ),
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
          data: (data) => _DashboardBody(data: data),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = (data['user'] as Map?)?.cast<String, dynamic>() ?? {};
    final kpis = (data['kpis'] as Map?)?.cast<String, dynamic>() ?? {};
    final chart = (data['chart'] as List?) ?? [];
    final topCampaigns = (data['topCampaigns'] as List?) ?? [];
    final liveOffers = data['liveOffers'] ?? 0;
    final name = user['name']?.toString() ?? '';

    final clicks = (kpis['clicks'] as Map?)?.cast<String, dynamic>() ?? {};
    final conversions = (kpis['conversions'] as Map?)?.cast<String, dynamic>() ?? {};
    final earnings = (kpis['earnings'] as Map?)?.cast<String, dynamic>() ?? {};

    final firstName = name.trim().split(' ').first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
      children: [
        FadeSlideIn(
          child: AffHeroCard(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting().toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: Colors.white.withValues(alpha: 0.65)),
                ),
                const SizedBox(height: 6),
                Text(
                  firstName.isNotEmpty ? firstName : 'Affiliate',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.8, height: 1.1),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _PulseDot(),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '$liveOffers live offers to promote today',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          index: 1,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'CLICKS',
                    value: clicks['value']?.toString() ?? '0',
                    icon: Icons.near_me_rounded,
                    color: AffColors.purpleEnd,
                    trend: clicks['trend'] != null ? '${clicks['trend']}% vs yesterday' : null,
                    trendUp: clicks['direction']?.toString() != 'down',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'CONVERSIONS',
                    value: conversions['value']?.toString() ?? '0',
                    icon: Icons.autorenew_rounded,
                    color: const Color(0xFFE0359B),
                    trend: conversions['mtd'] != null ? 'MTD: ${conversions['mtd']}' : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          index: 2,
          child: _StatTile(
            label: 'EARNINGS THIS WEEK',
            value: _currency.format(
              (earnings['value'] is num) ? earnings['value'] as num : num.tryParse(earnings['value']?.toString() ?? '') ?? 0,
            ),
            icon: Icons.currency_rupee_rounded,
            color: const Color(0xFFE08A1E),
            big: true,
          ),
        ),
        const SizedBox(height: 26),
        FadeSlideIn(
          index: 3,
          child: AffSectionHeader(
            title: '7-Day Performance',
            action: 'View report',
            onActionTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
          ),
        ),
        FadeSlideIn(
          index: 4,
          child: AffCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _LegendPill(color: AffColors.purpleEnd, label: 'Clicks'),
                    _LegendPill(color: Color(0xFFEC4899), label: 'Conversions'),
                    _LegendPill(color: Color(0xFFF59E0B), label: 'Earnings'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 170,
                  child: chart.isEmpty ? const EmptyState(message: 'No chart data yet', icon: Icons.show_chart) : _Chart(chart: chart),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),
        const FadeSlideIn(index: 5, child: AffSectionHeader(title: 'Top Campaigns')),
        if (topCampaigns.isEmpty)
          const EmptyState(message: 'No campaign activity yet', icon: Icons.campaign_outlined)
        else
          FadeSlideIn(
            index: 6,
            child: AffCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  for (var i = 0; i < topCampaigns.length; i++)
                    _CampaignRow(
                      campaign: (topCampaigns[i] as Map?)?.cast<String, dynamic>() ?? {},
                      rank: i + 1,
                      last: i == topCampaigns.length - 1,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 7 + 7 * _c.value,
              height: 7 + 7 * _c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AffColors.success.withValues(alpha: 0.5 * (1 - _c.value)),
              ),
            ),
            Container(width: 7, height: 7, decoration: const BoxDecoration(color: AffColors.success, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}

class _LegendPill extends StatelessWidget {
  const _LegendPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AffColors.inkMuted)),
        ],
      ),
    );
  }
}

/// White bento stat card: label, purple-gradient icon chip, bold value,
/// optional green trend row — matches the screenshot's Clicks/Conversions/
/// Earnings tiles.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.trendUp = true,
    this.big = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool trendUp;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final chip = AffIconChip(icon: icon, color: color, size: 42, solid: big);

    final labelText = Text(
      label,
      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AffColors.inkMuted, letterSpacing: 1.1),
    );
    final valueText = Text(
      value,
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AffColors.ink, height: 1.1, letterSpacing: -1),
    );

    final content = big
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [labelText, const SizedBox(height: 6), FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: valueText)],
                  ),
                ),
                chip,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [labelText, chip]),
                const SizedBox(height: 12),
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: valueText),
                if (trend != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (trendUp) const Icon(Icons.trending_up_rounded, size: 14, color: AffColors.success),
                      if (trendUp) const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          trend!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: trendUp ? AffColors.success : AffColors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );

    return AffCard(padding: const EdgeInsets.fromLTRB(18, 18, 18, 18), child: content);
  }
}

class _CampaignRow extends StatelessWidget {
  const _CampaignRow({required this.campaign, required this.rank, this.last = false});
  final Map<String, dynamic> campaign;
  final int rank;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final name = (campaign['name'] ?? campaign['offerName'] ?? campaign['offer_name'] ?? 'Campaign').toString();
    final earningsRaw = campaign['earnings'] ?? campaign['totalEarnings'] ?? campaign['value'] ?? 0;
    final earnings = (earningsRaw is num) ? earningsRaw : num.tryParse(earningsRaw.toString()) ?? 0;
    final conversions = campaign['conversions'];
    final initials = name.isNotEmpty ? name.trim().substring(0, name.trim().length >= 2 ? 2 : 1).toUpperCase() : '?';
    final maxEarnings = campaign['maxEarnings'];
    final progress = maxEarnings is num && maxEarnings > 0 ? (earnings / maxEarnings).clamp(0.0, 1.0).toDouble() : 0.6;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AffColors.hairline, width: 1))),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(gradient: AffColors.gradient, borderRadius: BorderRadius.circular(14)),
                child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
              ),
              if (rank <= 3)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: [const Color(0xFFF8AF18), const Color(0xFF94A3B8), const Color(0xFFD97706)][rank - 1],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5))),
                    Text(_currency.format(earnings), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AffColors.success)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        Container(color: AffColors.hairline),
                        FractionallySizedBox(widthFactor: progress, child: Container(decoration: const BoxDecoration(gradient: AffColors.gradient))),
                      ],
                    ),
                  ),
                ),
                if (conversions != null) ...[
                  const SizedBox(height: 4),
                  Text('$conversions conversions', style: const TextStyle(fontSize: 11, color: AffColors.inkMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.chart});

  final List chart;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < chart.length; i++) {
      final m = (chart[i] as Map?)?.cast<String, dynamic>() ?? {};
      final v = m['earnings'] ?? m['value'] ?? m['conversions'] ?? m['clicks'] ?? 0;
      final y = (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
      spots.add(FlSpot(i.toDouble(), y));
    }
    return LineChart(
      LineChartData(
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: AffColors.hairline, strokeWidth: 1, dashArray: [4, 4]),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AffColors.midnight,
            tooltipRoundedRadius: 12,
            getTooltipItems: (spots) =>
                spots.map((s) => LineTooltipItem(_currency.format(s.y), const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))).toList(),
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            gradient: const LinearGradient(colors: [AffColors.purpleStart, AffColors.purpleEnd]),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, data) => spot.x == data.spots.last.x,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 5, color: Colors.white, strokeWidth: 3, strokeColor: AffColors.purpleEnd),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [AffColors.purpleEnd.withValues(alpha: 0.22), AffColors.purpleEnd.withValues(alpha: 0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
