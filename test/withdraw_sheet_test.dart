import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loothat_app/features/affiliate/profile/presentation/edit_account_screen.dart';
import 'package:loothat_app/features/affiliate/profile/presentation/profile_providers.dart';
import 'package:loothat_app/features/affiliate/wallet/presentation/wallet_providers.dart';
import 'package:loothat_app/features/affiliate/wallet/presentation/withdraw_sheet.dart';

void main() {
  Future<void> pumpSheet(WidgetTester tester, {List<String> types = const ['upi', 'bank'], Map<String, dynamic> profile = const {}}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        gatewayStatusProvider.overrideWith((ref) async => types),
        profileProvider.overrideWith((ref) async => profile),
      ],
      child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WithdrawSheet()))),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  String text(WidgetTester tester, String label) =>
      tester.widget<TextField>(find.widgetWithText(TextField, label)).controller!.text;

  Finder byHint(String hint) => find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == hint);

  testWidgets('amount cannot exceed 50,000 or have letters/extra decimals', (tester) async {
    await pumpSheet(tester);
    final field = find.widgetWithText(TextField, 'Amount (₹10 - ₹50,000)');
    await tester.enterText(field, '40000');
    expect(text(tester, 'Amount (₹10 - ₹50,000)'), '40000');
    await tester.enterText(field, '400000'); // above max: rejected
    expect(text(tester, 'Amount (₹10 - ₹50,000)'), '40000');
    await tester.enterText(field, '12a');
    expect(text(tester, 'Amount (₹10 - ₹50,000)'), '40000');
    await tester.enterText(field, '10.505'); // 3 decimals: rejected
    expect(text(tester, 'Amount (₹10 - ₹50,000)'), '40000');
    await tester.enterText(field, '10.5');
    expect(text(tester, 'Amount (₹10 - ₹50,000)'), '10.5');
  });

  testWidgets('saved UPI ID is shown read-only (no input to edit it)', (tester) async {
    await pumpSheet(tester, profile: {'upi': 'rahul@okhdfc'});
    expect(find.text('PAYING TO'), findsOneWidget);
    expect(find.text('rahul@okhdfc'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'UPI ID'), findsNothing);
    expect(find.text('Change'), findsOneWidget);
  });

  testWidgets('opens on Bank when only bank details are saved', (tester) async {
    await pumpSheet(tester, profile: {'accNo': '123456789012', 'ifsc': 'hdfc0001234'});
    expect(find.text('123456789012'), findsOneWidget);
    expect(find.text('HDFC0001234'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // only the amount
  });

  testWidgets('nothing saved: asks to add it in the profile', (tester) async {
    await pumpSheet(tester, profile: const {});
    expect(find.textContaining('No UPI ID saved yet'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
  });

  testWidgets('invalid saved UPI ID blocks withdrawal and asks to update it', (tester) async {
    await pumpSheet(tester, profile: {'upi': 'not-a-upi'});
    expect(find.textContaining('is not valid'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
  });

  group('Edit account payout inputs', () {
    Future<void> pumpEdit(WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: EditAccountScreen(profile: {}))));
      await tester.pump(const Duration(milliseconds: 600));
    }

    String value(WidgetTester tester, Finder f) => tester.widget<TextField>(f).controller!.text;

    testWidgets('account number is digits only, max 18', (tester) async {
      await pumpEdit(tester);
      final field = byHint('Account number');
      await tester.enterText(field, '1' * 30);
      expect(value(tester, field).length, 18);
      await tester.enterText(field, '12ab34');
      expect(value(tester, field), '1234');
    });

    testWidgets('IFSC is upper-case alphanumeric, max 11', (tester) async {
      await pumpEdit(tester);
      final field = byHint('e.g. HDFC0001234');
      await tester.enterText(field, 'hdfc0001234xyz');
      expect(value(tester, field), 'HDFC0001234');
      await tester.enterText(field, 'ab-12 !');
      expect(value(tester, field), 'AB12');
    });
  });
}
