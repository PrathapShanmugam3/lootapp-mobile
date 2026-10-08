import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/chat_message.dart';

class ChatRepository {
  ChatRepository(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getMessages({String type = 'initial', int? beforeId, int? afterId}) async {
    final res = await _client.dio.get('/api/chat', queryParameters: {
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

  Future<void> sendMessage(String text) async {
    final formData = FormData.fromMap({'text': text});
    final res = await _client.dio.post('/api/chat', data: formData);
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
  }

  Future<void> reopen() async {
    final res = await _client.dio.post('/api/chat/reopen');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
  }
}
