import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/affiliate/presentation/affiliate_shell.dart';
import '../network/role.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshStream(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loggingIn = state.matchedLocation == '/login';
      final splash = state.matchedLocation == '/splash';
      final resettingPassword = state.matchedLocation == '/reset-password';

      if (auth.status == AuthStatus.unknown) {
        return (splash || resettingPassword) ? null : '/splash';
      }
      if (auth.status == AuthStatus.unauthenticated) {
        return (loggingIn || resettingPassword) ? null : '/login';
      }
      // authenticated
      if (loggingIn || splash) {
        return _homeFor(auth.user!.role);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(
        path: '/affiliate',
        builder: (context, state) => const AffiliateShell(),
        routes: [
          GoRoute(path: 'offers/:offId', builder: (c, s) => AffiliateShell(deepLinkOfferId: s.pathParameters['offId'])),
        ],
      ),
    ],
  );
});

/// The mobile app is user-only: every verified account lands in the
/// affiliate portal.
String _homeFor(AppRole role) =>
    role == AppRole.unverified ? '/login' : '/affiliate';

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

/// Bridges Riverpod's [authControllerProvider] state changes into a
/// [Listenable] so go_router's redirect re-evaluates on login/logout.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}
