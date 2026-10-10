import 'package:flutter_test/flutter_test.dart';
import 'package:loothat_app/core/push/push_service.dart';

void main() {
  test('new-offer push opens the offer detail', () {
    expect(PushService.locationFor({'type': 'offer', 'offId': 'ab12cd'}), '/affiliate/offers/ab12cd');
    expect(PushService.locationFor({'route': '/offer-detail?o=xy99'}), '/affiliate/offers/xy99');
  });

  test('chat reply push opens the Chat tab', () {
    expect(PushService.locationFor({'route': '/chat'}), '/affiliate?tab=chat');
  });

  test('anything else opens the Notifications list', () {
    expect(PushService.locationFor({'route': '/home'}), '/affiliate/notifications');
    expect(PushService.locationFor({}), '/affiliate/notifications');
  });
}
