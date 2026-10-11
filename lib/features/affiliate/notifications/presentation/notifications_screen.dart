import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/common.dart';
import '../../presentation/widgets/affiliate_design.dart';
import '../../offers/presentation/offer_detail_screen.dart';
import '../domain/notification.dart';
import 'notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawAsync = ref.watch(notificationsProvider);
    final notesAsync = rawAsync;

    return Scaffold(
      backgroundColor: AffColors.pageBg,
      appBar: AffHeader(
        title: 'Notifications',
        subtitle: 'Updates on your account',
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
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
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(message: 'No notifications yet', icon: Icons.notifications_none_rounded),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final i = idx;
                final n = notes[i];
                return FadeSlideIn(
                  index: i,
                  child: _NotificationCard(
                    note: n,
                    onTap: () async {
                      if (!n.isRead) {
                        await ref.read(notificationsRepositoryProvider).markRead(id: n.id);
                        ref.invalidate(notificationsProvider);
                      }
                      final offId = n.offId;
                      if (offId != null && context.mounted) {
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => OfferDetailScreen(offId: offId)));
                      }
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

/// One notification row. "New offer" notifications also show the offer's
/// banner image and a "View offer" hint, and open the offer when tapped.
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.note, required this.onTap});

  final AppNotification note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final n = note;
    final isOffer = n.type == 'offer' || n.offId != null;
    final image = n.imageUrl;
    return AffCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: Image.network(
                  image.replaceFirst(RegExp(r'^http://'), 'https://'),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AffColors.chipLilac,
                    alignment: Alignment.center,
                    child: Icon(Icons.local_offer_rounded, color: AffColors.purpleEnd, size: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AffIconChip(
                icon: isOffer ? Icons.local_offer_rounded : (n.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded),
                color: n.isRead ? AffColors.inkFaint : (isOffer ? AffColors.pink : AffColors.purpleEnd),
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
                    if (n.message.isNotEmpty) ...[const SizedBox(height: 3), Text(n.message, style: TextStyle(fontSize: 12.5, color: AffColors.inkMuted, height: 1.35))],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (n.createdAt != null && n.createdAt!.isNotEmpty)
                          Expanded(
                            child: Text(n.createdAt!, style: TextStyle(fontSize: 11, color: AffColors.inkFaint)),
                          )
                        else
                          const Spacer(),
                        if (n.offId != null)
                          Text(
                            'View offer →',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AffColors.purpleEnd),
                          ),
                      ],
                    ),
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
        ],
      ),
    );
  }
}
