import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import '../../presentation/admin_providers.dart';
import 'admin_user_detail_screen.dart';
import 'admin_user_form_screen.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(adminRepositoryProvider).getUsers();
  }

  void _search() {
    setState(() => _future = ref.read(adminRepositoryProvider).getUsers(search: _searchCtrl.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PortalHeader(title: 'Users'),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_alt),
        label: const Text('New user'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminUserFormScreen())).then((_) => _search()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search users…',
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
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
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
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => AdminUserDetailScreen(id: u['id'], userId: u['user_id']?.toString() ?? '')))
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
