import '../../../../core/network/api_client.dart';

/// Raw pass-through repository — the dashboard payload's `chart` and
/// `topCampaigns` shapes aren't rigidly documented, so the screen reads them
/// defensively as `Map<String, dynamic>` rather than a brittle typed model.
class DashboardRepository {
  DashboardRepository(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _client.dio.get('/api/dashboard');
    if (!res.isSuccess) {
      throw ApiException(res.message, statusCode: res.statusCode);
    }
    return res.body;
  }
}
