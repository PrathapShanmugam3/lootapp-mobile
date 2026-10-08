import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/user.dart';

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  Future<AppUser> login({required String mobile, required String password, String? recaptchaToken}) async {
    final res = await _client.dio.post('/api/auth/login', data: {
      'mobile': mobile,
      'password': password,
      if (recaptchaToken != null) 'recaptchaToken': recaptchaToken,
    });
    if (!res.isSuccess) {
      throw ApiException(res.message, statusCode: res.statusCode);
    }
    final userJson = res.body['user'] as Map<String, dynamic>;
    return AppUser.fromJson(userJson);
  }

  Future<void> signup({
    required String name,
    required String mobile,
    required String email,
    required String password,
    String? recaptchaToken,
  }) async {
    final res = await _client.dio.post('/api/auth/signup', data: {
      'name': name,
      'mobile': mobile,
      'email': email,
      'password': password,
      if (recaptchaToken != null) 'recaptchaToken': recaptchaToken,
    });
    if (!res.isSuccess) {
      throw ApiException(res.message, statusCode: res.statusCode);
    }
  }

  Future<void> forgotPassword({required String email, String? recaptchaToken}) async {
    final res = await _client.dio.post('/api/auth/forgot-password', data: {
      'email': email,
      if (recaptchaToken != null) 'recaptchaToken': recaptchaToken,
    });
    if (!res.isSuccess) {
      throw ApiException(res.message, statusCode: res.statusCode);
    }
  }

  Future<void> resetPassword({required String token, required String newPassword}) async {
    final res = await _client.dio.post('/api/auth/reset-password', data: {
      'token': token,
      'newPassword': newPassword,
    });
    if (!res.isSuccess) {
      throw ApiException(res.message, statusCode: res.statusCode);
    }
  }

  Future<void> logout() async {
    try {
      await _client.dio.post('/api/auth/logout');
    } finally {
      await _client.clearSession();
    }
  }

  /// Returns null if there's no valid session (401), rather than throwing —
  /// used for app-launch session restore.
  Future<AppUser?> me() async {
    try {
      final res = await _client.dio.get('/api/auth/me');
      if (!res.isSuccess) return null;
      return AppUser.fromJson(res.body['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      rethrow;
    }
  }
}
