import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

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

  /// Multipart field name the chat endpoint reads an attached picture from.
  static const imageField = 'image';

  Future<void> sendMessage(String text, {XFile? image}) async {
    final formData = FormData.fromMap({
      'text': text,
      if (image != null) imageField: MultipartFile.fromBytes(await image.readAsBytes(), filename: image.name),
    });
    final res = await _client.dio.post('/api/chat', data: formData);
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
  }

  Future<void> reopen() async {
    final res = await _client.dio.post('/api/chat/reopen');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
  }
}
