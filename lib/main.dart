import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/push/push_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PushService.init();
  runApp(const ProviderScope(child: LootHatApp()));
}

class LootHatApp extends ConsumerStatefulWidget {
  const LootHatApp({super.key});

  @override
  ConsumerState<LootHatApp> createState() => _LootHatAppState();
}

class _LootHatAppState extends ConsumerState<LootHatApp> {
  @override
  void initState() {
    super.initState();
    // Kick off session restore as soon as the widget tree is up — the
    // router's redirect logic sits on AuthStatus.unknown (splash) until
    // this resolves to authenticated/unauthenticated.
    Future.microtask(() => ref.read(authControllerProvider.notifier).bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'LootHat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // The "1a Polished Violet" design is a fixed light theme — it was
      // never designed with a dark variant, and previously following the
      // system's dark-mode setting made every screen's background and
      // surfaces render near-black (scheme.surface under a dark
      // ColorScheme.fromSeed) while the UI still assumed light surfaces.
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
