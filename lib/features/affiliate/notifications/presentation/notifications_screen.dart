import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/common.dart';
import '../../presentation/sample_data.dart';
import '../../presentation/widgets/affiliate_design.dart';
import 'notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawAsync = ref.watch(notificationsProvider);
    final sample = isSample(rawAsync);
    final notesAsync = withSample(rawAsync, SampleData.notifications);

    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: AffHeader(
        title: 'Notifications',
        subtitle: 'Updates on your account',
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.white, textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            onPressed: sample
                ? null
                : () async {
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
              return ListView(
                children: const [SizedBox(height: 120), EmptyState(message: 'No notifications yet', icon: Icons.notifications_none_rounded)],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              itemCount: notes.length + (sample ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                if (sample && idx == 0) return SampleDataBanner(onRetry: () => ref.invalidate(notificationsProvider));
                final i = sample ? idx - 1 : idx;
                final n = notes[i];
                return FadeSlideIn(
                  index: i,
                  child: AffCard(
                    padding: const EdgeInsets.all(14),
                    onTap: sample
                        ? null
                        : () async {
                            await ref.read(notificationsRepositoryProvider).markRead(id: n.id);
                            ref.invalidate(notificationsProvider);
                          },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AffIconChip(
                          icon: n.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                          color: n.isRead ? AffColors.inkFaint : AffColors.purpleEnd,
                          size: 42,
                          solid: !n.isRead,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: TextStyle(fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800, fontSize: 14, color: AffColors.ink),
                              ),
                              if (n.message.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(n.message, style: const TextStyle(fontSize: 12.5, color: AffColors.inkMuted, height: 1.35)),
                              ],
                              if (n.createdAt != null && n.createdAt!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(n.createdAt!, style: const TextStyle(fontSize: 11, color: AffColors.inkFaint)),
                              ],
                            ],
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            margin: const EdgeInsets.only(top: 4, left: 8),
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(color: AffColors.gold, shape: BoxShape.circle),
                          ),
                      ],
                    ),
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
