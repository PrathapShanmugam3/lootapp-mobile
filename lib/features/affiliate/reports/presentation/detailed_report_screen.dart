import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/sample_data.dart';
import '../../presentation/widgets/affiliate_design.dart';
import 'reports_providers.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
const _pageSize = 8;

class DetailedReportScreen extends ConsumerStatefulWidget {
  const DetailedReportScreen({
    super.key,
    required this.offId,
    required this.offerName,
    this.startDate,
    this.endDate,
  });

  final String offId;
  final String offerName;
  final String? startDate;
  final String? endDate;

  @override
  ConsumerState<DetailedReportScreen> createState() => _DetailedReportScreenState();
}

class _DetailedReportScreenState extends ConsumerState<DetailedReportScreen> {
  String _statusFilter = 'All';
  String _search = '';
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final filter = DetailedReportFilter(offId: widget.offId, startDate: widget.startDate, endDate: widget.endDate);
    final rawAsync = ref.watch(detailedReportProvider(filter));
    final sample = isSample(rawAsync);
    final reportAsync = withSample(rawAsync, SampleData.detailedReport);

    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: AffHeader(title: widget.offerName, subtitle: 'Click-level report'),
      body: reportAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: 'Failed to load report.\n$e',
          onRetry: () => ref.invalidate(detailedReportProvider(filter)),
        ),
        data: (data) => _Body(
          sample: sample,
          onRetry: () => ref.invalidate(detailedReportProvider(filter)),
          data: data,
          statusFilter: _statusFilter,
          search: _search,
          page: _page,
          onStatusChanged: (s) => setState(() {
            _statusFilter = s;
            _page = 0;
          }),
          onSearchChanged: (s) => setState(() {
            _search = s;
            _page = 0;
          }),
          onPageChanged: (p) => setState(() => _page = p),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    this.sample = false,
    this.onRetry,
    required this.data,
    required this.statusFilter,
    required this.search,
    required this.page,
    required this.onStatusChanged,
    required this.onSearchChanged,
    required this.onPageChanged,
  });

  final bool sample;
  final VoidCallback? onRetry;
  final Map<String, dynamic> data;
  final String statusFilter;
  final String search;
  final int page;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final stats = (data['stats'] as Map?)?.cast<String, dynamic>() ?? {};
    final allRows = ((data['rows'] as List?) ?? [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();

    final statusCounts = <String, int>{};
    for (final r in allRows) {
      final s = (r['status'] ?? '').toString();
      statusCounts[s] = (statusCounts[s] ?? 0) + 1;
    }

    var rows = statusFilter == 'All' ? allRows : allRows.where((r) => (r['status'] ?? '').toString() == statusFilter).toList();
    if (search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      rows = rows.where((r) {
        final userVal = ((r['userIdentity'] as Map?)?['value'] ?? '').toString().toLowerCase();
        final referVal = ((r['referIdentity'] as Map?)?['value'] ?? '').toString().toLowerCase();
        final clickId = (r['clickId'] ?? '').toString().toLowerCase();
        return userVal.contains(q) || referVal.contains(q) || clickId.contains(q);
      }).toList();
    }

    final totalPages = (rows.length / _pageSize).ceil().clamp(1, 999999);
    final clampedPage = page.clamp(0, totalPages - 1);
    final pageRows = rows.skip(clampedPage * _pageSize).take(_pageSize).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        if (sample) SampleDataBanner(onRetry: onRetry),
        Row(
          children: [
            Expanded(child: StatTile(label: 'Clicks', value: (stats['totalClicks'] ?? 0).toString(), icon: Icons.ads_click)),
            const SizedBox(width: 10),
            Expanded(child: StatTile(label: 'Conversions', value: (stats['totalConversions'] ?? 0).toString(), icon: Icons.check_circle_outline)),
            const SizedBox(width: 10),
            Expanded(child: StatTile(label: 'Earnings', value: _currency.format((stats['totalEarnings'] as num?) ?? 0), icon: Icons.payments_outlined)),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _StatusPill(label: 'All (${allRows.length})', selected: statusFilter == 'All', onTap: () => onStatusChanged('All')),
              for (final entry in statusCounts.entries) ...[
                const SizedBox(width: 8),
                _StatusPill(
                  label: '${entry.key} (${entry.value})',
                  selected: statusFilter == entry.key,
                  onTap: () => onStatusChanged(entry.key),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search user, refer, or click ID',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 14),
        if (rows.isEmpty)
          const EmptyState(message: 'No clicks match this filter', icon: Icons.inbox_outlined)
        else ...[
          for (var i = 0; i < pageRows.length; i++) _ClickRow(index: clampedPage * _pageSize + i + 1, row: pageRows[i]),
          if (totalPages > 1) ...[
            const SizedBox(height: 12),
            Center(
              child: Wrap(
                spacing: 6,
                children: [
                  for (var p = 0; p < totalPages; p++)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: p == clampedPage ? AppColors.primary : null,
                        foregroundColor: p == clampedPage ? Colors.white : null,
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => onPageChanged(p),
                      child: Text('${p + 1}'),
                    ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      showCheckmark: false,
      labelStyle: TextStyle(color: selected ? Colors.white : AffColors.inkMuted, fontWeight: FontWeight.w700),
    );
  }
}

class _ClickRow extends StatelessWidget {
  const _ClickRow({required this.index, required this.row});

  final int index;
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final userIdentity = (row['userIdentity'] as Map?)?.cast<String, dynamic>() ?? {};
    final referIdentity = (row['referIdentity'] as Map?)?.cast<String, dynamic>() ?? {};
    final status = (row['status'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AffCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('#$index', style: const TextStyle(color: AffColors.inkFaint, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (row['clickId'] ?? '').toString(),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusChip(text: status, color: statusColor(status)),
              ],
            ),
            const SizedBox(height: 8),
            if (userIdentity['value'] != null)
              Text('${userIdentity['label'] ?? 'User'}: ${userIdentity['value']}', style: const TextStyle(fontSize: 13)),
            if (referIdentity['value'] != null)
              Text('${referIdentity['label'] ?? 'Refer'}: ${referIdentity['value']}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              '${row['date'] ?? ''} ${row['time'] ?? ''}'.trim(),
              style: const TextStyle(color: AffColors.inkFaint, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}
