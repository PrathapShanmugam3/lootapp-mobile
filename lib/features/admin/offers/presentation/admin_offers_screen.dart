import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/common.dart';
import '../../presentation/admin_providers.dart';
import 'admin_offer_form_screen.dart';

class AdminOffersScreen extends ConsumerWidget {
  const AdminOffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(adminOffersProvider);

    return Scaffold(
      appBar: PortalHeader(title: 'Offers'),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New offer'),
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AdminOfferFormScreen()))
            .then((_) => ref.invalidate(adminOffersProvider)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(adminOffersProvider.future),
        child: offersAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: 'Failed to load offers.\n$e', onRetry: () => ref.invalidate(adminOffersProvider)),
          data: (offers) {
            if (offers.isEmpty) return const EmptyState(message: 'No offers yet', icon: Icons.local_offer_outlined);
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: offers.length,
              itemBuilder: (context, i) {
                final o = offers[i];
                final offId = o['off_id']?.toString() ?? '';
                final status = (o['offer_status'] ?? '').toString();
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: statusColor(status).withValues(alpha: 0.12), child: Icon(Icons.local_offer, color: statusColor(status), size: 18)),
                    title: Text(o['offer_name']?.toString() ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('ID: $offId · Caps: ${o['caps'] ?? '-'}'),
                    trailing: StatusChip(text: status, color: statusColor(status)),
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => AdminOfferFormScreen(offId: offId)))
                        .then((_) => ref.invalidate(adminOffersProvider)),
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
