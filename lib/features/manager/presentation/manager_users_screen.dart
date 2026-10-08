import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import 'manager_providers.dart';

class ManagerUsersScreen extends ConsumerStatefulWidget {
  const ManagerUsersScreen({super.key});

  @override
  ConsumerState<ManagerUsersScreen> createState() => _ManagerUsersScreenState();
}

class _ManagerUsersScreenState extends ConsumerState<ManagerUsersScreen> {
  final _searchCtrl = TextEditingController();
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(managerRepositoryProvider).getUsers();
  }

  void _search() {
    setState(() => _future = ref.read(managerRepositoryProvider).getUsers(search: _searchCtrl.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PortalHeader(title: 'Users'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, email, mobile…',
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
                final users = (snap.data?['users'] as List?) ?? [];
                if (users.isEmpty) return const EmptyState(message: 'No users found', icon: Icons.people_outline);
                return RefreshIndicator(
                  onRefresh: () async => _search(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      final u = (users[i] as Map).cast<String, dynamic>();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white, size: 18)),
                          title: Text(u['name']?.toString() ?? ''),
                          subtitle: Text(u['mobile']?.toString() ?? u['email']?.toString() ?? ''),
                          trailing: Text('₹${u['balance'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ManagerUserDetailScreen(id: u['id'], userId: u['user_id']?.toString() ?? '')),
                          ),
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

class ManagerUserDetailScreen extends ConsumerStatefulWidget {
  const ManagerUserDetailScreen({super.key, required this.id, required this.userId});

  final dynamic id;
  final String userId;

  @override
  ConsumerState<ManagerUserDetailScreen> createState() => _ManagerUserDetailScreenState();
}

class _ManagerUserDetailScreenState extends ConsumerState<ManagerUserDetailScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;
  late TextEditingController _nameCtrl, _emailCtrl, _mobileCtrl, _upiCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ref.read(managerRepositoryProvider).getUserDetail(widget.id);
      _user = user;
      _nameCtrl = TextEditingController(text: user['name']?.toString() ?? '');
      _emailCtrl = TextEditingController(text: user['email']?.toString() ?? '');
      _mobileCtrl = TextEditingController(text: user['mobile']?.toString() ?? '');
      _upiCtrl = TextEditingController(text: user['upi']?.toString() ?? '');
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PortalHeader(
        title: widget.userId,
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Performance',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ManagerUserPerformanceScreen(userId: widget.userId)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const LoadingState()
          : _error != null
              ? ErrorState(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    GradientHeroCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Balance', style: TextStyle(color: Colors.white70)),
                          Text('₹${_user?['balance'] ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                    const SizedBox(height: 12),
                    TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                    const SizedBox(height: 12),
                    TextField(controller: _mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile')),
                    const SizedBox(height: 12),
                    TextField(controller: _upiCtrl, decoration: const InputDecoration(labelText: 'UPI ID')),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save changes'),
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final result = await ref.read(managerRepositoryProvider).updateUser(widget.id, {
        'name': _nameCtrl.text,
        'email': _emailCtrl.text,
        'mobile': _mobileCtrl.text,
        'upi': _upiCtrl.text,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class ManagerUserPerformanceScreen extends ConsumerWidget {
  const ManagerUserPerformanceScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: PortalHeader(title: 'Performance'),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ref.read(managerRepositoryProvider).getUserPerformance(userId),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingState();
          if (snap.hasError) return ErrorState(message: '${snap.error}');
          final data = snap.data ?? {};
          final transactions = (data['transactions'] as List?) ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: StatTile(label: 'Clicks', value: '${data['totalClicks'] ?? 0}', icon: Icons.ads_click)),
                  const SizedBox(width: 10),
                  Expanded(child: StatTile(label: 'Conversions', value: '${data['totalConversions'] ?? 0}', icon: Icons.check_circle_outline)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: StatTile(label: 'Conv. rate', value: '${data['conversionRate'] ?? 0}%')),
                  const SizedBox(width: 10),
                  Expanded(child: StatTile(label: 'Total credited', value: '₹${data['totalCredited'] ?? 0}')),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Recent transactions'),
              if (transactions.isEmpty)
                const EmptyState(message: 'No transactions', icon: Icons.receipt_long_outlined)
              else
                ...transactions.map((t) {
                  final m = (t as Map).cast<String, dynamic>();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(m['comment']?.toString() ?? m['type']?.toString() ?? ''),
                      subtitle: Text('${m['date'] ?? ''} ${m['time'] ?? ''}'),
                      trailing: Text('₹${m['amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
