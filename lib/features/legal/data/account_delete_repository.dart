import '../../../core/network/api_client.dart';

class AccountDeleteRepository {
  AccountDeleteRepository(this._client);

  final ApiClient _client;

  Future<void> requestAccountDeletion({
    required String email,
    required String reason,
    String? recaptchaToken,
  }) async {
    final res = await _client.dio.post('/api/public/account-delete', data: {
      'email': email,
      'reason': reason,
      if (recaptchaToken != null) 'recaptchaToken': recaptchaToken,
    });
    if (!res.isSuccess) {
      throw ApiException(res.message, statusCode: res.statusCode);
    }
  }
}
