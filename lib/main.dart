import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/push/push_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/presentation/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PushService.init();
  await ThemeController.load();
  runApp(const ProviderScope(child: LootHatApp()));
}

class LootHatApp extends ConsumerStatefulWidget {
  const LootHatApp({super.key});

  @override
  ConsumerState<LootHatApp> createState() => _LootHatAppState();
}

class _LootHatAppState extends ConsumerState<LootHatApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Kick off session restore as soon as the widget tree is up — the
    // router's redirect logic sits on AuthStatus.unknown (splash) until
    // this resolves to authenticated/unauthenticated.
    Future.microtask(() => ref.read(authControllerProvider.notifier).bootstrap());
    PushService.onOpen = _openFromPush;
  }

  /// A push tapped before the session is restored (cold start) would be
  /// overridden by the splash → /affiliate redirect, so hold it until the
  /// user is authenticated.
  String? _pendingPushLocation;

  void _openFromPush(String location) {
    if (ref.read(authControllerProvider).status == AuthStatus.authenticated) {
      ref.read(routerProvider).go(location);
    } else {
      _pendingPushLocation = location;
    }
  }

  @override
  void dispose() {
    PushService.onOpen = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _isDark(ThemeMode mode) =>
      mode == ThemeMode.dark || (mode == ThemeMode.system && PlatformDispatcher.instance.platformBrightness == Brightness.dark);

  /// Screens read colours from static [AppColors]/[AffColors] getters (many
  /// inside const-free but otherwise cached widgets), so a palette switch has
  /// to rebuild every element, not just Theme.of dependents. Rebuilding in
  /// place keeps navigation and screen state intact.
  void _applyPalette(ThemeMode mode) {
    final dark = _isDark(mode);
    if (dark == Palette.dark) return;
    setState(() => Palette.dark = dark);
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  void didChangePlatformBrightness() => _applyPalette(ref.read(themeModeProvider));

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    ref.listen<ThemeMode>(themeModeProvider, (_, mode) => _applyPalette(mode));
    ref.listen(authControllerProvider, (_, auth) {
      final pending = _pendingPushLocation;
      if (pending == null || auth.status != AuthStatus.authenticated) return;
      _pendingPushLocation = null;
      // After the login redirect to /affiliate has run.
      Future.microtask(() => ref.read(routerProvider).go(pending));
    });
    Palette.dark = _isDark(ref.read(themeModeProvider));

    return MaterialApp.router(
      title: 'LootHat',
      debugShowCheckedModeBanner: false,
      // One theme built from the active palette — light/dark switching is
      // driven by [Palette], not MaterialApp's themeMode.
      theme: AppTheme.current(),
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
