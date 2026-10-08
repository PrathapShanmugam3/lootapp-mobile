import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final client = ref.watch(apiClientProvider).requireValue;
  return AdminRepository(client);
});

final adminDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getDashboard();
});

final adminOffersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).getOffers();
});

final adminOfferDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, offId) {
  return ref.watch(adminRepositoryProvider).getOfferDetail(offId);
});

final adminGatewaysProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).getOfferGateways();
});

final adminManagersActivityProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).getManagersActivity();
});
