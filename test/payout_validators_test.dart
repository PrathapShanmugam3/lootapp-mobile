import 'package:flutter_test/flutter_test.dart';
import 'package:loothat_app/core/utils/payout_validators.dart';

void main() {
  test('UPI ID: optional, but must be name@handle', () {
    expect(PayoutValidators.upi(''), isNull);
    expect(PayoutValidators.upi('rahul@okhdfc'), isNull);
    expect(PayoutValidators.upi('rahul.k-1@ybl'), isNull);
    expect(PayoutValidators.upi('rahulokhdfc'), isNotNull);
    expect(PayoutValidators.upi('rahul@ok hdfc'), isNotNull);
  });

  test('account number: 9–18 digits, required with IFSC', () {
    expect(PayoutValidators.account('', ifsc: ''), isNull);
    expect(PayoutValidators.account('', ifsc: 'HDFC0001234'), isNotNull);
    expect(PayoutValidators.account('12345678', ifsc: 'HDFC0001234'), isNotNull);
    expect(PayoutValidators.account('123456789', ifsc: 'HDFC0001234'), isNull);
    expect(PayoutValidators.account('1' * 19, ifsc: 'HDFC0001234'), isNotNull);
  });

  test('IFSC: AAAA0XXXXXX, required with account number', () {
    expect(PayoutValidators.ifsc('', account: ''), isNull);
    expect(PayoutValidators.ifsc('', account: '123456789'), isNotNull);
    expect(PayoutValidators.ifsc('hdfc0001234', account: '123456789'), isNull);
    expect(PayoutValidators.ifsc('HDFC1001234', account: '123456789'), isNotNull); // 5th char must be 0
    expect(PayoutValidators.ifsc('HDFC000123', account: '123456789'), isNotNull);
  });
}
