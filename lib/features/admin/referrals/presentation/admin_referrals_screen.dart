import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/admin_providers.dart';

class AdminReferralsScreen extends ConsumerStatefulWidget {
  const AdminReferralsScreen({super.key});

  @override
  ConsumerState<AdminReferralsScreen> createState() => _AdminReferralsScreenState();
}

class _AdminReferralsScreenState extends ConsumerState<AdminReferralsScreen> {
  final _searchCtrl = TextEditingController();
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(adminRepositoryProvider).getReferrals();
  }

  void _search() => setState(() => _future = ref.read(adminRepositoryProvider).getReferrals(search: _searchCtrl.text));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PortalHeader(title: 'Referrals'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search referrals…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _search),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return const LoadingState();
                if (snap.hasError) return ErrorState(message: '${snap.error}', onRetry: _search);
                final referrals = (snap.data?['referrals'] as List?) ?? [];
                if (referrals.isEmpty) return const EmptyState(message: 'No referrals found', icon: Icons.group_outlined);
                return RefreshIndicator(
                  onRefresh: () async => _search(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: referrals.length,
                    itemBuilder: (context, i) {
                      final r = (referrals[i] as Map).cast<String, dynamic>();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.link, color: Colors.white, size: 16)),
                          title: Text(r['offer_name']?.toString() ?? r['offer_id']?.toString() ?? ''),
                          subtitle: Text('Affiliate: ${r['aff_id'] ?? ''} · Code: ${r['refer_code'] ?? ''}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => AdminReferralDetailScreen(referral: r)))
                              .then((_) => _search()),
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

class AdminReferralDetailScreen extends ConsumerStatefulWidget {
  const AdminReferralDetailScreen({super.key, required this.referral});

  final Map<String, dynamic> referral;

  @override
  ConsumerState<AdminReferralDetailScreen> createState() => _AdminReferralDetailScreenState();
}

class _AdminReferralDetailScreenState extends ConsumerState<AdminReferralDetailScreen> {
  static const _eventNums = [1, 2, 3, 4, 5];
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final key in ['offer_id', 'aff_id', 'refer_pay_id', 'refer_code', 'ref_telegram']) {
      _controllers[key] = TextEditingController(text: widget.referral[key]?.toString() ?? '');
    }
    for (final n in _eventNums) {
      _controllers['eve_${n}_user_po'] = TextEditingController(text: widget.referral['eve_${n}_user_po']?.toString() ?? '');
      _controllers['eve_${n}_refer_po'] = TextEditingController(text: widget.referral['eve_${n}_refer_po']?.toString() ?? '');
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final fields = <String, dynamic>{};
    _controllers.forEach((k, c) => fields[k] = c.text);
    try {
      final result = await ref.read(adminRepositoryProvider).updateReferral(widget.referral['id'], fields);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PortalHeader(title: 'Referral detail'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _controllers['offer_id'], decoration: const InputDecoration(labelText: 'Offer ID')),
          const SizedBox(height: 12),
          TextField(controller: _controllers['aff_id'], decoration: const InputDecoration(labelText: 'Affiliate ID')),
          const SizedBox(height: 12),
          TextField(controller: _controllers['refer_pay_id'], decoration: const InputDecoration(labelText: 'Refer pay ID')),
          const SizedBox(height: 12),
          TextField(controller: _controllers['refer_code'], decoration: const InputDecoration(labelText: 'Refer code')),
          const SizedBox(height: 12),
          TextField(controller: _controllers['ref_telegram'], decoration: const InputDecoration(labelText: 'Telegram')),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Payout split'),
          for (final n in _eventNums)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(child: TextField(controller: _controllers['eve_${n}_user_po'], decoration: InputDecoration(labelText: 'Event $n user'))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: _controllers['eve_${n}_refer_po'], decoration: InputDecoration(labelText: 'Event $n refer'))),
                ],
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save changes'),
          ),
        ],
      ),
    );
  }
}
