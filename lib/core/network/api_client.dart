import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

/// Base URL for the Loot Hat Node.js/Express backend, and the public site
/// URL (used for building shareable referral-link previews, etc).
///
/// The backend authenticates via an httpOnly session cookie (see
/// lootapp-api/src/utils/jwt.js), so the app relies on a persisted
/// [PersistCookieJar] rather than storing the token itself.
///
/// Override at build/run time to point at a different environment, e.g. for
/// local dev against `npm run dev` in lootapp-api (PORT=4000):
///   flutter run --dart-define=API_BASE=http://10.0.2.2:4000 --dart-define=SITE_URL=http://10.0.2.2:3000   (Android emulator)
///   flutter run --dart-define=API_BASE=http://LAN_IP:4000 --dart-define=SITE_URL=http://LAN_IP:3000   (physical device over USB/Wi-Fi)
/// Defaults to the deployed Vercel backend/frontend.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://lootapp-api.vercel.app',
  );

  static const String siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'https://lootapp-ui.vercel.app',
  );
}

class ApiClient {
  ApiClient._(this.dio, this.cookieJar);

  final Dio dio;
  final PersistCookieJar? cookieJar;

  static ApiClient? _instance;

  static Future<ApiClient> getInstance() async {
    if (_instance != null) return _instance!;

    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // On web, the browser's own cookie jar already carries the httpOnly
    // session cookie on every XHR — there's no app-sandboxed filesystem to
    // persist a cookie jar to, and dio_cookie_manager doesn't apply there.
    PersistCookieJar? cookieJar;
    if (!kIsWeb) {
      final appDocDir = await getApplicationDocumentsDirectory();
      cookieJar = PersistCookieJar(
        storage: FileStorage('${appDocDir.path}/.cookies/'),
      );
      dio.interceptors.add(CookieManager(cookieJar));
    } else {
      dio.options.extra['withCredentials'] = true;
    }

    _instance = ApiClient._(dio, cookieJar);
    return _instance!;
  }

  // On web the httpOnly session cookie is cleared server-side by
  // /api/auth/logout; there's no client-side jar to clear.
  Future<void> clearSession() => cookieJar?.deleteAll() ?? Future.value();
}

/// Normalized API error surfaced to the UI layer.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

extension ResponseX on Response {
  /// The backend's uniform `{ success, message, ...data }` envelope.
  Map<String, dynamic> get body => data is Map<String, dynamic>
      ? data as Map<String, dynamic>
      : <String, dynamic>{};

  bool get isSuccess => body['success'] == true;

  String get message => (body['message'] as String?) ?? 'Something went wrong.';
}
