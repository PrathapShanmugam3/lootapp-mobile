import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_providers.dart';
import '../data/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(apiClientProvider).requireValue;
  return DashboardRepository(client);
});

final dashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) {
  return ref.watch(dashboardRepositoryProvider).getDashboard();
});
