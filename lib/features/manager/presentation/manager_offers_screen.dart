import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common.dart';
import 'manager_providers.dart';

class ManagerOffersScreen extends ConsumerWidget {
  const ManagerOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(managerOffersProvider);

    return Scaffold(
      appBar: PortalHeader(title: 'Offers'),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(managerOffersProvider.future),
        child: offersAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: 'Failed to load offers.\n$e', onRetry: () => ref.invalidate(managerOffersProvider)),
          data: (offers) {
            if (offers.isEmpty) return const EmptyState(message: 'No offers found', icon: Icons.local_offer_outlined);
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: offers.length,
              itemBuilder: (context, i) {
                final o = offers[i];
                final offId = (o['off_id'] ?? o['offId'])?.toString() ?? '';
                final name = (o['offer_name'] ?? o['offerName'] ?? '').toString();
                final status = (o['offer_status'] ?? o['offerStatus'] ?? '').toString();
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: const Icon(Icons.local_offer, color: AppColors.primary, size: 18),
                    ),
                    title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('ID: $offId'),
                    trailing: StatusChip(text: status.isEmpty ? '-' : status, color: statusColor(status)),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ManagerOfferDetailScreen(offId: offId)),
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

class ManagerOfferDetailScreen extends ConsumerWidget {
  const ManagerOfferDetailScreen({super.key, required this.offId});

  final String offId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(managerOfferDetailProvider(offId));

    return Scaffold(
      appBar: PortalHeader(title: offId),
      body: detailAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: 'Failed to load offer.\n$e', onRetry: () => ref.invalidate(managerOfferDetailProvider(offId))),
        data: (offer) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(offer['offer_name']?.toString() ?? '', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: offer.entries
                      .where((e) => e.value != null && e.value.toString().isNotEmpty)
                      .map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 140, child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                                Expanded(child: Text(e.value.toString(), style: const TextStyle(fontSize: 12.5))),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
