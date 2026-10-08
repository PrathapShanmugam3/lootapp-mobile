import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/chat_message.dart';

/// Single repository covering all `/api/emp/*` endpoints — the manager
/// portal's surface mirrors the admin read-only side plus payout retry and
/// a support inbox, so one repository keeps the mapping simple and visible
/// in one place rather than splitting into many near-empty files.
class ManagerRepository {
  ManagerRepository(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _client.dio.get('/api/emp/dashboard');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return (res.body['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<List<Map<String, dynamic>>> getOffers() async {
    final res = await _client.dio.get('/api/emp/offers');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return ((res.body['offers'] as List?) ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> getOfferDetail(String offId) async {
    final res = await _client.dio.get('/api/emp/offers/$offId');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return (res.body['offer'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> getReferrals({String? search, int page = 1}) async {
    final res = await _client.dio.get('/api/emp/referrals', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
    });
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> getClicks({Map<String, dynamic>? filters, int page = 1}) async {
    final res = await _client.dio.get('/api/emp/clicks', queryParameters: {...?filters, 'page': page});
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> getClickFilters() async {
    final res = await _client.dio.get('/api/emp/clicks/filters');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> getPaymentLogs({Map<String, dynamic>? filters, int page = 1}) async {
    final res = await _client.dio.get('/api/emp/payment-logs', queryParameters: {...?filters, 'page': page});
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> getAffiliateReport(String affId) async {
    final res = await _client.dio.get('/api/emp/affiliates/$affId/report');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> getAffiliateOfferDrilldown(String affId, String offId) async {
    final res = await _client.dio.get('/api/emp/affiliates/$affId/offers/$offId/drilldown');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> updatePayRecord(dynamic id, Map<String, dynamic> fields) async {
    final res = await _client.dio.put('/api/emp/pay-records/$id', data: fields);
    return res.body;
  }

  Future<Map<String, dynamic>> repayPayRecord(dynamic id) async {
    final res = await _client.dio.post('/api/emp/pay-records/$id/repay');
    return res.body;
  }

  Future<Map<String, dynamic>> getUsers({String? search, int page = 1, int limit = 20}) async {
    final res = await _client.dio.get('/api/emp/users', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'limit': limit,
    });
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> getUserDetail(dynamic id) async {
    final res = await _client.dio.get('/api/emp/users/$id');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return (res.body['user'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> updateUser(dynamic id, Map<String, dynamic> fields) async {
    final res = await _client.dio.put('/api/emp/users/$id', data: fields);
    return res.body;
  }

  Future<Map<String, dynamic>> getUserPerformance(String userId) async {
    final res = await _client.dio.get('/api/emp/users/$userId/performance');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> resolvePendingPayment({required String trxId, required bool approve}) async {
    final res = await _client.dio.post('/api/emp/pending-payments/resolve', data: {'trxId': trxId, 'approve': approve});
    return res.body;
  }

  // --- Support inbox ---

  Future<Map<String, dynamic>> getConversations({String? search, int page = 1}) async {
    final res = await _client.dio.get('/api/emp/support/conversations', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
    });
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> getChat(String userId, {String type = 'initial', int? beforeId, int? afterId}) async {
    final res = await _client.dio.get('/api/emp/support/chat/$userId', queryParameters: {
      'type': type,
      if (beforeId != null) 'beforeId': beforeId,
      if (afterId != null) 'afterId': afterId,
    });
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    final list = (res.body['messages'] as List?) ?? [];
    return {
      'messages': list.map((e) => ChatMessageModel.fromJson((e as Map).cast<String, dynamic>())).toList(),
      'status': res.body['status']?.toString() ?? 'open',
    };
  }

  Future<void> sendChatMessage(String userId, String text) async {
    final formData = FormData.fromMap({'text': text});
    final res = await _client.dio.post('/api/emp/support/chat/$userId', data: formData);
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
  }

  Future<void> closeChat(String userId) async {
    final res = await _client.dio.put('/api/emp/support/chat/$userId/close');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
  }

  Future<void> reopenChat(String userId) async {
    final res = await _client.dio.put('/api/emp/support/chat/$userId/reopen');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
  }

  Future<List<String>> getMessageTemplates() async {
    final res = await _client.dio.get('/api/emp/message-templates');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    final list = (res.body['templates'] as List?) ?? [];
    return list.map((e) {
      if (e is Map) return (e['text'] ?? e['message'] ?? e['content'] ?? e.toString()).toString();
      return e.toString();
    }).toList();
  }
}
