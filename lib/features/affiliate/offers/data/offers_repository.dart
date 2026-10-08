import '../../../../core/network/api_client.dart';

class OffersRepository {
  OffersRepository(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> getOffers() async {
    final res = await _client.dio.get('/api/offers');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    final list = (res.body['offers'] as List?) ?? [];
    return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> getOfferDetail(String offId) async {
    final res = await _client.dio.get('/api/offers/$offId');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<void> updatePayoutSplit(String offId, Map<String, dynamic> splits) async {
    final res = await _client.dio.put('/api/offers/$offId/payout-split', data: splits);
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
  }

  Future<void> updateLandingTheme(String offId, String theme) async {
    final res = await _client.dio.put('/api/offers/$offId/landing-theme', data: {'theme': theme});
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
  }
}
