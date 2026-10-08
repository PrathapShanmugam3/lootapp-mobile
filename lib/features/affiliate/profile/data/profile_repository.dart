import '../../../../core/network/api_client.dart';

class ProfileRepository {
  ProfileRepository(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> getProfile() async {
    final res = await _client.dio.get('/api/profile');
    if (!res.isSuccess) throw ApiException(res.message, statusCode: res.statusCode);
    return (res.body['profile'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updatePayoutDetails({String? upi, String? accNo, String? ifsc}) async {
    final res = await _client.dio.put('/api/profile/payout-details', data: {
      if (upi != null) 'upi': upi,
      if (accNo != null) 'accNo': accNo,
      if (ifsc != null) 'ifsc': ifsc,
    });
    return res.body;
  }

  Future<Map<String, dynamic>> verifyPassword(String currentPassword) async {
    final res = await _client.dio.post('/api/profile/verify-password', data: {'currentPassword': currentPassword});
    return res.body;
  }

  Future<Map<String, dynamic>> changePassword({required String currentPassword, required String newPassword}) async {
    final res = await _client.dio.put('/api/profile/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    return res.body;
  }
}
