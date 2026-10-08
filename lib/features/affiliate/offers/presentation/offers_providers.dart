import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_providers.dart';
import '../data/offers_repository.dart';

final offersRepositoryProvider = Provider<OffersRepository>((ref) {
  final client = ref.watch(apiClientProvider).requireValue;
  return OffersRepository(client);
});

final offersListProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(offersRepositoryProvider).getOffers();
});

final offerDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, offId) {
  return ref.watch(offersRepositoryProvider).getOfferDetail(offId);
});
