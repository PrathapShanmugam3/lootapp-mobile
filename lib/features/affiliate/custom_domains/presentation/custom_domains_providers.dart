import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_providers.dart';
import '../data/custom_domains_repository.dart';

final customDomainsRepositoryProvider = Provider<CustomDomainsRepository>((ref) {
  final client = ref.watch(apiClientProvider).requireValue;
  return CustomDomainsRepository(client);
});

final customDomainsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(customDomainsRepositoryProvider).getDomains();
});
