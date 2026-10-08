import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/admin_providers.dart';

class AdminClicksScreen extends ConsumerStatefulWidget {
  const AdminClicksScreen({super.key});

  @override
  ConsumerState<AdminClicksScreen> createState() => _AdminClicksScreenState();
}

class _AdminClicksScreenState extends ConsumerState<AdminClicksScreen> {
  Future<Map<String, dynamic>>? _future;
  Map<String, dynamic>? _filters;
  String? _offId;
  String? _event;

  @override
  void initState() {
    super.initState();
    _future = ref.read(adminRepositoryProvider).getClicks();
    ref.read(adminRepositoryProvider).getClickFilters().then((f) {
      if (mounted) setState(() => _filters = f);
    }).catchError((_) {});
  }

  void _reload() {
    setState(() {
      _future = ref.read(adminRepositoryProvider).getClicks(filters: {
        if (_offId != null) 'offId': _offId,
        if (_event != null) 'event': _event,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final offers = (_filters?['offers'] as List?) ?? [];
    final events = (_filters?['events'] as List?) ?? [];

    return Scaffold(
      appBar: PortalHeader(title: 'Clicks'),
      body: Column(
        children: [
          if (_filters != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _offId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Offer', isDense: true),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All offers')),
                        ...offers.map((o) {
                          final m = (o as Map).cast<String, dynamic>();
                          return DropdownMenuItem(value: m['off_id']?.toString(), child: Text(m['off_name']?.toString() ?? '', overflow: TextOverflow.ellipsis));
                        }),
                      ],
                      onChanged: (v) {
                        _offId = v;
                        _reload();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _event,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Event', isDense: true),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All events')),
                        ...events.map((e) => DropdownMenuItem(value: e.toString(), child: Text(e.toString()))),
                      ],
                      onChanged: (v) {
                        _event = v;
                        _reload();
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return const LoadingState();
                if (snap.hasError) return ErrorState(message: '${snap.error}', onRetry: _reload);
                final clicks = (snap.data?['clicks'] as List?) ?? [];
                if (clicks.isEmpty) return const EmptyState(message: 'No clicks recorded', icon: Icons.ads_click);
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: clicks.length,
                    itemBuilder: (context, i) {
                      final c = (clicks[i] as Map).cast<String, dynamic>();
                      final converted = c['click_status'] == '1';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          leading: Icon(Icons.ads_click, color: converted ? AppColors.success : AppColors.primary),
                          title: Text(c['off_name']?.toString() ?? c['off_id']?.toString() ?? ''),
                          subtitle: Text('Affiliate: ${c['aff_id'] ?? ''} · ${c['date'] ?? ''} ${c['time'] ?? ''}'),
                          trailing: StatusChip(text: converted ? 'Converted' : 'Pending', color: statusColor(converted ? 'success' : 'pending')),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('IP: ${c['ip'] ?? '-'}', style: const TextStyle(fontSize: 12)),
                                  Text('Click ID: ${c['click_id'] ?? '-'}', style: const TextStyle(fontSize: 12)),
                                  Text('Sub1: ${c['aff_sub_1'] ?? '-'}  Sub2: ${c['aff_sub_2'] ?? '-'}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
