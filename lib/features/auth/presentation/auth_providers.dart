import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

final apiClientProvider = FutureProvider<ApiClient>((ref) => ApiClient.getInstance());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final clientAsync = ref.watch(apiClientProvider);
  final client = clientAsync.requireValue; // only read once resolved (see AuthController.bootstrap)
  return AuthRepository(client);
});

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.user});

  final AuthStatus status;
  final AppUser? user;

  static const initial = AuthState(status: AuthStatus.unknown);

  AuthState copyWith({AuthStatus? status, AppUser? user}) =>
      AuthState(status: status ?? this.status, user: user ?? this.user);
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(AuthState.initial);

  final Ref _ref;

  Future<void> bootstrap() async {
    await _ref.read(apiClientProvider.future);
    final repo = _ref.read(authRepositoryProvider);
    try {
      final user = await repo.me();
      state = user != null
          ? AuthState(status: AuthStatus.authenticated, user: user)
          : const AuthState(status: AuthStatus.unauthenticated);
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({required String mobile, required String password, String? recaptchaToken}) async {
    final repo = _ref.read(authRepositoryProvider);
    final user = await repo.login(mobile: mobile, password: password, recaptchaToken: recaptchaToken);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> logout() async {
    final repo = _ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref),
);
