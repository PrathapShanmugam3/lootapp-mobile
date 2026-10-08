import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common.dart';
import 'notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3EEFB),
      appBar: PortalHeader(
        title: 'Notifications',
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () async {
              await ref.read(notificationsRepositoryProvider).markRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(notificationsProvider.future),
        child: notesAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: 'Failed to load notifications.\n$e', onRetry: () => ref.invalidate(notificationsProvider)),
          data: (notes) {
            if (notes.isEmpty) {
              return const EmptyState(message: 'No notifications yet', icon: Icons.notifications_none);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = notes[i];
                return Card(
                  color: n.isRead ? null : AppColors.primary.withValues(alpha: 0.06),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: n.isRead ? Colors.grey.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.15),
                      child: Icon(Icons.notifications, size: 18, color: n.isRead ? Colors.grey : AppColors.primary),
                    ),
                    title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.w700)),
                    subtitle: Text(n.message),
                    trailing: n.isRead ? null : Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    onTap: () async {
                      await ref.read(notificationsRepositoryProvider).markRead(id: n.id);
                      ref.invalidate(notificationsProvider);
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
