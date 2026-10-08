import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import 'detailed_report_screen.dart';
import 'reports_providers.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

const _dateOptions = [
  ('today', 'Today'),
  ('yesterday', 'Yesterday'),
  ('last_7_days', 'Last 7 days'),
  ('last_30_days', 'Last 30 days'),
  ('this_month', 'This month'),
  ('custom', 'Custom range'),
];

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _dateOption = 'last_7_days';
  DateTime? _startDate;
  DateTime? _endDate;

  ReportsFilter get _filter => ReportsFilter(
        dateOption: _dateOption,
        startDate: _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null,
        endDate: _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null,
      );

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsProvider(_filter));

    return Scaffold(
      backgroundColor: const Color(0xFFF3EEFB),
      appBar: PortalHeader(
        title: 'Reports',
        actions: [
          PortalHeaderAction(
            icon: Icons.refresh,
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(reportsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(reportsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _FilterBar(
              dateOption: _dateOption,
              startDate: _startDate,
              endDate: _endDate,
              onOptionChanged: (opt) {
                setState(() => _dateOption = opt);
                if (opt == 'custom') _pickCustomRange();
              },
              onEditRange: _pickCustomRange,
            ),
            const SizedBox(height: 20),
            reportsAsync.when(
              loading: () => const SizedBox(height: 200, child: LoadingState(compact: true)),
              error: (e, _) => ErrorState(
                message: 'Failed to load reports.\n$e',
                onRetry: () => ref.invalidate(reportsProvider),
              ),
              data: (data) => _ReportsBody(data: data, filter: _filter),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.dateOption,
    required this.startDate,
    required this.endDate,
    required this.onOptionChanged,
    required this.onEditRange,
  });

  final String dateOption;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<String> onOptionChanged;
  final VoidCallback onEditRange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: dateOption,
          decoration: const InputDecoration(labelText: 'Period'),
          items: [
            for (final o in _dateOptions) DropdownMenuItem(value: o.$1, child: Text(o.$2)),
          ],
          onChanged: (v) {
            if (v != null) onOptionChanged(v);
          },
        ),
        if (dateOption == 'custom') ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onEditRange,
            icon: const Icon(Icons.date_range_outlined),
            label: Text(
              startDate != null && endDate != null
                  ? '${DateFormat('d MMM').format(startDate!)} – ${DateFormat('d MMM yyyy').format(endDate!)}'
                  : 'Pick date range',
            ),
          ),
        ],
      ],
    );
  }
}

class _ReportsBody extends StatelessWidget {
  const _ReportsBody({required this.data, required this.filter});

  final Map<String, dynamic> data;
  final ReportsFilter filter;

  @override
  Widget build(BuildContext context) {
    final current = (data['current'] as Map?)?.cast<String, dynamic>() ?? {};
    final previous = (data['previous'] as Map?)?.cast<String, dynamic>() ?? {};
    final campaigns = (data['campaigns'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _TrendStat(
                label: 'Total Clicks',
                value: (current['totalClicks'] ?? 0).toString(),
                current: current['totalClicks'],
                previous: previous['totalClicks'],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TrendStat(
                label: 'Total Conversions',
                value: (current['totalConversions'] ?? 0).toString(),
                current: current['totalConversions'],
                previous: previous['totalConversions'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _TrendStat(
          label: 'Total Revenue',
          value: _currency.format((current['totalEarnings'] as num?) ?? 0),
          current: current['totalEarnings'],
          previous: previous['totalEarnings'],
          fullWidth: true,
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Campaign breakdown'),
        if (campaigns.isEmpty)
          const EmptyState(message: 'No campaign activity for this period', icon: Icons.bar_chart_outlined)
        else
          ...campaigns.map((c) {
            final m = (c as Map?)?.cast<String, dynamic>() ?? {};
            final offId = (m['offId'] ?? '').toString();
            final name = (m['offerName'] ?? 'Campaign').toString();
            final clicks = (m['totalClicks'] as num?) ?? 0;
            final leads = (m['totalLeads'] as num?) ?? 0;
            final earnings = (m['totalEarnings'] as num?) ?? 0;
            final cvr = clicks > 0 ? (leads / clicks * 100) : 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DetailedReportScreen(
                      offId: offId,
                      offerName: name,
                      startDate: filter.startDate,
                      endDate: filter.endDate,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          Icon(
                            leads > 0 ? Icons.trending_up : Icons.remove_circle_outline,
                            size: 16,
                            color: leads > 0 ? AppColors.success : Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _MiniStat(label: 'Clicks', value: clicks.toString())),
                          Expanded(child: _MiniStat(label: 'Leads', value: leads.toString())),
                          Expanded(child: _MiniStat(label: 'CVR', value: '${cvr.toStringAsFixed(1)}%')),
                          Expanded(child: _MiniStat(label: 'Earned', value: _currency.format(earnings))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: clicks > 0 ? (leads / clicks).clamp(0, 1).toDouble() : 0,
                          minHeight: 6,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 10.5)),
      ],
    );
  }
}

class _TrendStat extends StatelessWidget {
  const _TrendStat({
    required this.label,
    required this.value,
    required this.current,
    required this.previous,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final dynamic current;
  final dynamic previous;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final cur = (current as num?)?.toDouble();
    final prev = (previous as num?)?.toDouble();
    String? trendText;
    bool trendUp = true;
    if (cur != null && prev != null) {
      if (prev == 0) {
        trendText = cur > 0 ? 'New' : null;
      } else {
        final pct = ((cur - prev) / prev * 100);
        trendUp = pct >= 0;
        trendText = '${pct.abs().toStringAsFixed(1)}%';
      }
    }
    return StatTile(label: label, value: value, trendText: trendText, trendUp: trendUp);
  }
}
