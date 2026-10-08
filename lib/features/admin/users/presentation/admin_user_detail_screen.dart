import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/admin_providers.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({super.key, required this.id, required this.userId});

  final dynamic id;
  final String userId;

  @override
  ConsumerState<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;
  bool _saving = false;
  late TextEditingController _nameCtrl, _emailCtrl, _mobileCtrl, _upiCtrl, _accNoCtrl, _ifscCtrl;
  String _status = '1';

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
      final user = await ref.read(adminRepositoryProvider).getUserDetail(widget.id);
      _user = user;
      _nameCtrl = TextEditingController(text: user['name']?.toString() ?? '');
      _emailCtrl = TextEditingController(text: user['email']?.toString() ?? '');
      _mobileCtrl = TextEditingController(text: user['mobile']?.toString() ?? '');
      _upiCtrl = TextEditingController(text: user['upi']?.toString() ?? '');
      _accNoCtrl = TextEditingController(text: user['acc_no']?.toString() ?? '');
      _ifscCtrl = TextEditingController(text: user['ifsc']?.toString() ?? '');
      _status = user['status']?.toString() ?? '1';
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final result = await ref.read(adminRepositoryProvider).updateUser(widget.id, {
        'name': _nameCtrl.text,
        'email': _emailCtrl.text,
        'mobile': _mobileCtrl.text,
        'upi': _upiCtrl.text,
        'accNo': _accNoCtrl.text,
        'ifsc': _ifscCtrl.text,
        'status': _status,
        'balance': _user?['balance'],
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setAccountState(String state) async {
    try {
      final result = await ref.read(adminRepositoryProvider).setAccountState(widget.id, state: state);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Account state updated to $state')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user?'),
        content: const Text('This cannot be undone. Users with click/payment history cannot be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final result = await ref.read(adminRepositoryProvider).deleteUser(widget.id);
      if (!mounted) return;
      if (result['success'] == true) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']?.toString() ?? 'Could not delete')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
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
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminUserPerformanceScreen(userId: widget.userId))),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Audit log',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AdminUserAuditLogScreen(id: widget.id, userId: widget.userId))),
          ),
          IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete', onPressed: _delete),
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
                    const SectionHeader(title: 'Account state'),
                    Wrap(
                      spacing: 8,
                      children: ['active', 'suspended', 'banned'].map((s) {
                        return ActionChip(
                          label: Text(s),
                          backgroundColor: statusColor(s).withValues(alpha: 0.12),
                          labelStyle: TextStyle(color: statusColor(s)),
                          onPressed: () => _setAccountState(s),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const SectionHeader(title: 'Profile'),
                    TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                    const SizedBox(height: 12),
                    TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
                    const SizedBox(height: 12),
                    TextField(controller: _mobileCtrl, decoration: const InputDecoration(labelText: 'Mobile')),
                    const SizedBox(height: 12),
                    TextField(controller: _upiCtrl, decoration: const InputDecoration(labelText: 'UPI ID')),
                    const SizedBox(height: 12),
                    TextField(controller: _accNoCtrl, decoration: const InputDecoration(labelText: 'Account number')),
                    const SizedBox(height: 12),
                    TextField(controller: _ifscCtrl, decoration: const InputDecoration(labelText: 'IFSC code')),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Role status'),
                      items: const {'1': 'Affiliate', '9': 'Manager', '69': 'Admin'}
                          .entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _status = v ?? _status),
                    ),
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
}

class AdminUserPerformanceScreen extends ConsumerWidget {
  const AdminUserPerformanceScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: PortalHeader(title: 'Performance'),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ref.read(adminRepositoryProvider).getUserPerformance(userId),
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

class AdminUserAuditLogScreen extends ConsumerWidget {
  const AdminUserAuditLogScreen({super.key, required this.id, required this.userId});

  final dynamic id;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: PortalHeader(title: 'Audit log — $userId'),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: ref.read(adminRepositoryProvider).getUserAuditLog(id),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const LoadingState();
          if (snap.hasError) return ErrorState(message: '${snap.error}');
          final log = snap.data ?? [];
          if (log.isEmpty) return const EmptyState(message: 'No audit history', icon: Icons.history);
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: log.length,
            itemBuilder: (context, i) {
              final entry = log[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.fiber_manual_record, size: 12, color: AppColors.primary),
                  title: Text(entry['action']?.toString() ?? ''),
                  subtitle: Text(entry['detail']?.toString() ?? ''),
                  trailing: Text(entry['createdAt']?.toString() ?? entry['created_at']?.toString() ?? '', style: const TextStyle(fontSize: 11)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
