import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/manager_repository.dart';

final managerRepositoryProvider = Provider<ManagerRepository>((ref) {
  final client = ref.watch(apiClientProvider).requireValue;
  return ManagerRepository(client);
});

final managerDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(managerRepositoryProvider).getDashboard();
});

final managerOffersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(managerRepositoryProvider).getOffers();
});

final managerOfferDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, offId) {
  return ref.watch(managerRepositoryProvider).getOfferDetail(offId);
});
