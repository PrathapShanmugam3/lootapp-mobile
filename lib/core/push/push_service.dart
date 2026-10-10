import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// OneSignal push notifications. The SDK only exists on Android/iOS, so every
/// call is a no-op on web and desktop (e.g. `flutter run -d chrome`).
class PushService {
  PushService._();

  static const oneSignalAppId = 'db4c7838-1fd3-4a67-84da-a02c9b00729d';

  static bool get _supported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  static bool _initialized = false;

  /// In-app location a tapped push points at, waiting for [onOpen] to be set
  /// (a cold start delivers the tap before the widget tree is up).
  static String? _pendingLocation;
  static void Function(String location)? _onOpen;

  /// Set by the app once it can navigate; receives a go_router location.
  static set onOpen(void Function(String location)? handler) {
    _onOpen = handler;
    final pending = _pendingLocation;
    if (handler != null && pending != null) {
      _pendingLocation = null;
      handler(pending);
    }
  }

  /// Call once at startup, before runApp.
  static void init() {
    if (!_supported || _initialized) return;
    if (kDebugMode) OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(oneSignalAppId);
    OneSignal.Notifications.addClickListener((event) {
      final location = locationFor(event.notification.additionalData ?? const {});
      if (_onOpen != null) {
        _onOpen!(location);
      } else {
        _pendingLocation = location;
      }
    });
    _initialized = true;
  }

  /// Maps the backend's push `data` (see oneSignalService.js) to an app
  /// route: offers open their detail page, chat replies open the Chat tab,
  /// everything else (wallet/approval updates) the Notifications list.
  @visibleForTesting
  static String locationFor(Map<String, dynamic> data) {
    final offId = data['offId']?.toString() ?? Uri.tryParse(data['route']?.toString() ?? '')?.queryParameters['o'];
    if (offId != null && offId.isNotEmpty) return '/affiliate/offers/${Uri.encodeComponent(offId)}';
    final route = data['route']?.toString() ?? '';
    if (route.startsWith('/chat')) return '/affiliate?tab=chat';
    return '/affiliate/notifications';
  }

  /// Links this device to the LootHat user so pushes can target them by
  /// their user id (OneSignal "External ID"), then asks for notification
  /// permission if the user hasn't answered yet.
  static Future<void> login({required String userId, String? name}) async {
    if (!_initialized || userId.isEmpty) return;
    try {
      await OneSignal.login(userId);
      if (name != null && name.isNotEmpty) OneSignal.User.addTagWithKey('name', name);
      if (!OneSignal.Notifications.permission) await OneSignal.Notifications.requestPermission(true);
    } catch (e) {
      debugPrint('OneSignal login failed: $e');
    }
  }

  /// Unlinks the device so a logged-out phone stops getting that user's pushes.
  static Future<void> logout() async {
    if (!_initialized) return;
    try {
      await OneSignal.logout();
    } catch (e) {
      debugPrint('OneSignal logout failed: $e');
    }
  }
}
