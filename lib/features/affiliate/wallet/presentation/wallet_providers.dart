import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_providers.dart';
import '../data/wallet_repository.dart';
import '../domain/wallet_models.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final client = ref.watch(apiClientProvider).requireValue;
  return WalletRepository(client);
});

final walletSummaryProvider = FutureProvider.autoDispose<WalletSummary>((ref) {
  return ref.watch(walletRepositoryProvider).getSummary();
});

final gatewayStatusProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(walletRepositoryProvider).getGatewayStatus();
});

class TransactionsNotifier extends AutoDisposeAsyncNotifier<List<WalletTransaction>> {
  int _page = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  @override
  Future<List<WalletTransaction>> build() async {
    _page = 1;
    final repo = ref.read(walletRepositoryProvider);
    final result = await repo.getTransactions(page: _page);
    final txns = result['transactions'] as List<WalletTransaction>;
    _hasMore = (result['currentPage'] as int) < (result['totalPages'] as int);
    return txns;
  }

  Future<void> loadMore() async {
    if (!_hasMore || state.isLoading) return;
    final repo = ref.read(walletRepositoryProvider);
    final nextPage = _page + 1;
    final result = await repo.getTransactions(page: nextPage);
    final newTxns = result['transactions'] as List<WalletTransaction>;
    _page = nextPage;
    _hasMore = (result['currentPage'] as int) < (result['totalPages'] as int);
    state = AsyncData([...state.value ?? [], ...newTxns]);
  }
}

final transactionsProvider = AsyncNotifierProvider.autoDispose<TransactionsNotifier, List<WalletTransaction>>(
  TransactionsNotifier.new,
);
