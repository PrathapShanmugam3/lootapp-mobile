import '../../../../core/network/api_client.dart';

class CustomDomainsRepository {
  CustomDomainsRepository(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> getDomains() async {
    final res = await _client.dio.get('/api/custom-domains');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    final list = (res.body['domains'] as List?) ?? [];
    return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  /// Returns the full response body (includes verificationToken + DNS
  /// instructions on success) so the UI can show the TXT-record panel.
  Future<Map<String, dynamic>> addDomain(String domain) async {
    final res = await _client.dio.post('/api/custom-domains', data: {'domain': domain});
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> verifyDomain(String id) async {
    final res = await _client.dio.post('/api/custom-domains/$id/verify');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<void> deleteDomain(String id) async {
    final res = await _client.dio.delete('/api/custom-domains/$id');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
  }
}
