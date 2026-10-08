import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/chat_message.dart';

/// Single repository covering `/api/admin/*` — the admin surface is large
/// (dashboard, offers CRUD, users CRUD, managers, referrals, clicks,
/// pending approvals, gateways, settings, redeem codes, account-delete
/// requests, support inbox) so it's kept in one place, grouped by section,
/// matching adminRoutes.js's own grouping comments.
class AdminRepository {
  AdminRepository(this._client);

  final ApiClient _client;

  // --- Dashboard ---
  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _client.dio.get('/api/admin/dashboard');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return (res.body['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  // --- Offers ---
  Future<List<Map<String, dynamic>>> getOffers({String? status}) async {
    final res = await _client.dio.get('/api/admin/offers', queryParameters: {if (status != null) 'status': status});
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return ((res.body['offers'] as List?) ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> getOfferDetail(String offId) async {
    final res = await _client.dio.get('/api/admin/offers/$offId');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return (res.body['offer'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> createOffer(Map<String, dynamic> fields) async {
    final res = await _client.dio.post('/api/admin/offers', data: fields);
    return res.body;
  }

  Future<Map<String, dynamic>> updateOffer(String offId, Map<String, dynamic> fields) async {
    final res = await _client.dio.put('/api/admin/offers/$offId', data: fields);
    return res.body;
  }

  Future<Map<String, dynamic>> deleteOffer(String offId) async {
    final res = await _client.dio.delete('/api/admin/offers/$offId');
    return res.body;
  }

  Future<Map<String, dynamic>> duplicateOffer(String offId) async {
    final res = await _client.dio.post('/api/admin/offers/$offId/duplicate');
    return res.body;
  }

  Future<List<Map<String, dynamic>>> getOfferGateways() async {
    final res = await _client.dio.get('/api/admin/offers/gateways');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return ((res.body['gateways'] as List?) ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  // --- Users ---
  Future<Map<String, dynamic>> getUsers({String? search, String? status, String? balanceFilter, int page = 1, int limit = 20}) async {
    final res = await _client.dio.get('/api/admin/users', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null) 'status': status,
      if (balanceFilter != null) 'balanceFilter': balanceFilter,
      'page': page,
      'limit': limit,
    });
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> getUserDetail(dynamic id) async {
    final res = await _client.dio.get('/api/admin/users/$id');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return (res.body['user'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> fields) async {
    final res = await _client.dio.post('/api/admin/users', data: fields);
    return res.body;
  }

  Future<Map<String, dynamic>> updateUser(dynamic id, Map<String, dynamic> fields) async {
    final res = await _client.dio.put('/api/admin/users/$id', data: fields);
    return res.body;
  }

  Future<Map<String, dynamic>> deleteUser(dynamic id) async {
    final res = await _client.dio.delete('/api/admin/users/$id');
    return res.body;
  }

  Future<Map<String, dynamic>> getUserPerformance(String userId) async {
    final res = await _client.dio.get('/api/admin/users/$userId/performance');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> setAccountState(dynamic id, {required String state, String? reason}) async {
    final res = await _client.dio.put('/api/admin/users/$id/account-state', data: {'state': state, if (reason != null) 'reason': reason});
    return res.body;
  }

  Future<List<Map<String, dynamic>>> getUserAuditLog(dynamic id) async {
    final res = await _client.dio.get('/api/admin/users/$id/audit-log');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return ((res.body['log'] as List?) ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  // --- Managers activity ---
  Future<List<Map<String, dynamic>>> getManagersActivity() async {
    final res = await _client.dio.get('/api/admin/managers/activity');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return ((res.body['managers'] as List?) ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> getManagerActivityDetail(dynamic id) async {
    final res = await _client.dio.get('/api/admin/managers/$id/activity');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  // --- Referrals ---
  Future<Map<String, dynamic>> getReferrals({String? search, int page = 1, int limit = 20}) async {
    final res = await _client.dio.get('/api/admin/referrals', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'limit': limit,
    });
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> getReferralDetail(dynamic id) async {
    final res = await _client.dio.get('/api/admin/referrals/$id');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return (res.body['referral'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> updateReferral(dynamic id, Map<String, dynamic> fields) async {
    final res = await _client.dio.put('/api/admin/referrals/$id', data: fields);
    return res.body;
  }

  // --- Clicks ---
  Future<Map<String, dynamic>> getClicks({Map<String, dynamic>? filters, int page = 1, int limit = 50}) async {
    final res = await _client.dio.get('/api/admin/clicks', queryParameters: {...?filters, 'page': page, 'limit': limit});
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> getClickFilters() async {
    final res = await _client.dio.get('/api/admin/clicks/filters');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> getClickDetail(dynamic id) async {
    final res = await _client.dio.get('/api/admin/clicks/$id');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return (res.body['click'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> updateClick(dynamic id, Map<String, dynamic> fields) async {
    final res = await _client.dio.put('/api/admin/clicks/$id', data: fields);
    return res.body;
  }

  // --- Approval queues ---
  Future<Map<String, dynamic>> getPendingConversions({Map<String, dynamic>? filters, int page = 1}) async {
    final res = await _client.dio.get('/api/admin/pending-conversions', queryParameters: {...?filters, 'page': page});
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> resolvePendingConversion({required String clickId, required String event, required bool approve}) async {
    final res = await _client.dio.post('/api/admin/pending-conversions/resolve', data: {'clickId': clickId, 'event': event, 'approve': approve});
    return res.body;
  }

  Future<Map<String, dynamic>> getPendingPayments({int page = 1}) async {
    final res = await _client.dio.get('/api/admin/pending-payments', queryParameters: {'page': page});
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> resolvePendingPayment({required String trxId, required bool approve}) async {
    final res = await _client.dio.post('/api/admin/pending-payments/resolve', data: {'trxId': trxId, 'approve': approve});
    return res.body;
  }

  // --- Reports / payments ---
  Future<Map<String, dynamic>> getPaymentLogs({Map<String, dynamic>? filters, int page = 1}) async {
    final res = await _client.dio.get('/api/admin/payment-logs', queryParameters: {...?filters, 'page': page});
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> getFailedPayments({String? offId, int page = 1}) async {
    final res = await _client.dio.get('/api/admin/failed-payments', queryParameters: {if (offId != null) 'offId': offId, 'page': page});
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> getAffiliateReport(String affId) async {
    final res = await _client.dio.get('/api/admin/affiliates/$affId/report');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> repayPayRecord(dynamic id) async {
    final res = await _client.dio.post('/api/admin/pay-records/$id/repay');
    return res.body;
  }

  Future<Map<String, dynamic>> updatePayRecord(dynamic id, Map<String, dynamic> fields) async {
    final res = await _client.dio.put('/api/admin/pay-records/$id', data: fields);
    return res.body;
  }

  Future<List<Map<String, dynamic>>> getOfferReports() async {
    final res = await _client.dio.get('/api/admin/offer-reports');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return ((res.body['offers'] as List?) ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> getTopEarners({int page = 1}) async {
    final res = await _client.dio.get('/api/admin/top-earners', queryParameters: {'page': page});
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  // --- Redeem codes ---
  Future<Map<String, dynamic>> getRedeemCodes({int page = 1}) async {
    final res = await _client.dio.get('/api/admin/redeem-codes', queryParameters: {'page': page});
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> createRedeemCode({required num value, int maxUses = 1, String? expiresAt}) async {
    final res = await _client.dio.post('/api/admin/redeem-codes', data: {
      'value': value,
      'maxUses': maxUses,
      if (expiresAt != null) 'expiresAt': expiresAt,
    });
    return res.body;
  }

  Future<Map<String, dynamic>> toggleRedeemCode(dynamic id, bool isActive) async {
    final res = await _client.dio.put('/api/admin/redeem-codes/$id/toggle', data: {'isActive': isActive});
    return res.body;
  }

  // --- Account delete requests ---
  Future<Map<String, dynamic>> getAccountDeleteRequests({String? search, String? status, int page = 1}) async {
    final res = await _client.dio.get('/api/admin/account-delete-requests', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null) 'status': status,
      'page': page,
    });
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> updateAccountDeleteRequestStatus(dynamic id, String status) async {
    final res = await _client.dio.put('/api/admin/account-delete-requests/$id', data: {'status': status});
    return res.body;
  }

  // --- Settings / gateways / IP allowlist ---
  Future<Map<String, dynamic>> getSettings() async {
    final res = await _client.dio.get('/api/admin/settings');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return (res.body['settings'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> fields) async {
    final res = await _client.dio.put('/api/admin/settings', data: fields);
    return res.body;
  }

  Future<List<Map<String, dynamic>>> getGatewaysFull() async {
    final res = await _client.dio.get('/api/admin/gateways');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return ((res.body['gateways'] as List?) ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<List<Map<String, dynamic>>> getWhitelistedIps() async {
    final res = await _client.dio.get('/api/admin/ip-whitelist');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return ((res.body['ips'] as List?) ?? []).map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  Future<Map<String, dynamic>> reconcilePayments() async {
    final res = await _client.dio.post('/api/admin/reconcile-payments');
    return res.body;
  }

  // --- Support inbox (same shape as emp) ---
  Future<Map<String, dynamic>> getConversations({String? search, int page = 1}) async {
    final res = await _client.dio.get('/api/admin/support/conversations', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
    });
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return res.body;
  }

  Future<Map<String, dynamic>> getChat(String userId, {String type = 'initial', int? beforeId, int? afterId}) async {
    final res = await _client.dio.get('/api/admin/support/chat/$userId', queryParameters: {
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
    final res = await _client.dio.post('/api/admin/support/chat/$userId', data: formData);
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
  }

  Future<void> closeChat(String userId) async {
    final res = await _client.dio.put('/api/admin/support/chat/$userId/close');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
  }

  Future<void> reopenChat(String userId) async {
    final res = await _client.dio.put('/api/admin/support/chat/$userId/reopen');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
  }

  Future<List<String>> getMessageTemplates() async {
    final res = await _client.dio.get('/api/admin/message-templates/by-role', queryParameters: {'role': 'admin'});
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    final list = (res.body['templates'] as List?) ?? [];
    return list.map((e) {
      if (e is Map) return (e['text'] ?? e['message'] ?? e['content'] ?? e.toString()).toString();
      return e.toString();
    }).toList();
  }
}
