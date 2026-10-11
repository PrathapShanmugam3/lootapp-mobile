import '../../../../core/network/api_client.dart';

class ReportsRepository {
  ReportsRepository(this._client);

  final ApiClient _client;

  /// The reports API returns its fields at the top level
  /// (`{success, current, previous, campaigns}` / `{success, stats, rows}`),
  /// not under `data` — reading `data` alone made every number 0.
  static Map<String, dynamic> _payload(dynamic body) {
    if (body is! Map) return {};
    final data = body['data'];
    return (data is Map ? data : body).cast<String, dynamic>();
  }

  /// [dateOption] one of: today, yesterday, last_7_days, last_30_days,
  /// this_month, custom. [startDate]/[endDate] (yyyy-MM-dd) only apply when
  /// dateOption is custom.
  Future<Map<String, dynamic>> getReports({
    required String dateOption,
    String? startDate,
    String? endDate,
  }) async {
    final res = await _client.dio.get('/api/reports', queryParameters: {
      'dateOption': dateOption,
      if (dateOption == 'custom' && startDate != null) 'startDate': startDate,
      if (dateOption == 'custom' && endDate != null) 'endDate': endDate,
    });
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return _payload(res.body);
  }

  Future<Map<String, dynamic>> getDetailedReport({
    required String offId,
    String? startDate,
    String? endDate,
  }) async {
    final res = await _client.dio.get('/api/reports/$offId', queryParameters: {
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    });
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return _payload(res.body);
  }
}
