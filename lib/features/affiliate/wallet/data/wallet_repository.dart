import '../../../../core/network/api_client.dart';
import '../domain/wallet_models.dart';

class WalletRepository {
  WalletRepository(this._client);

  final ApiClient _client;

  Future<WalletSummary> getSummary() async {
    final res = await _client.dio.get('/api/wallet');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return WalletSummary.fromJson(res.body);
  }

  Future<List<String>> getGatewayStatus() async {
    final res = await _client.dio.get('/api/wallet/gateway-status');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    final list = (res.body['activeTypes'] as List?) ?? [];
    return list.map((e) => e.toString()).toList();
  }

  Future<Map<String, dynamic>> getTransactions({int page = 1}) async {
    final res = await _client.dio.get('/api/wallet/transactions', queryParameters: {'page': page});
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    final list = (res.body['transactions'] as List?) ?? [];
    return {
      'transactions': list.map((e) => WalletTransaction.fromJson((e as Map).cast<String, dynamic>())).toList(),
      'totalPages': res.body['totalPages'] ?? 1,
      'currentPage': res.body['currentPage'] ?? page,
    };
  }

  Future<Map<String, dynamic>> withdraw({
    required String type,
    required double amount,
    String? upiId,
    String? accountNo,
    String? ifscCode,
  }) async {
    final res = await _client.dio.post('/api/wallet/withdraw', data: {
      'type': type,
      'amount': amount,
      if (upiId != null) 'upiId': upiId,
      if (accountNo != null) 'accountNo': accountNo,
      if (ifscCode != null) 'ifscCode': ifscCode,
    });
    return res.body;
  }
}
