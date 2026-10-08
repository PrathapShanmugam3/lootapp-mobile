import '../../../../core/network/api_client.dart';
import '../domain/notification.dart';

class NotificationsRepository {
  NotificationsRepository(this._client);

  final ApiClient _client;

  Future<List<AppNotification>> getNotifications() async {
    final res = await _client.dio.get('/api/notifications');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    final list = (res.body['notifications'] as List?) ?? [];
    return list.map((e) => AppNotification.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<void> markRead({dynamic id}) async {
    final res = await _client.dio.post('/api/notifications/read', data: {if (id != null) 'id': id});
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
  }
}
