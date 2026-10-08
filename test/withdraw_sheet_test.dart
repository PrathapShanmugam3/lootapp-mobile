import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loothat_app/features/affiliate/wallet/presentation/wallet_providers.dart';
import 'package:loothat_app/features/affiliate/wallet/presentation/withdraw_sheet.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [gatewayStatusProvider.overrideWith((ref) async => ['bank'])],
      child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: WithdrawSheet()))),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  String text(WidgetTester tester, String label) =>
      tester.widget<TextField>(find.widgetWithText(TextField, label)).controller!.text;

  testWidgets('amount cannot exceed 50,000 or have letters/extra decimals', (tester) async {
    await pump(tester);
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

  testWidgets('account number is digits only, max 18', (tester) async {
    await pump(tester);
    final field = find.widgetWithText(TextField, 'Account number');
    await tester.enterText(field, '1' * 30);
    expect(text(tester, 'Account number').length, 18);
    await tester.enterText(field, '12ab34');
    expect(text(tester, 'Account number'), '1234');
  });

  testWidgets('IFSC is upper-case alphanumeric, max 11', (tester) async {
    await pump(tester);
    final field = find.widgetWithText(TextField, 'IFSC code');
    await tester.enterText(field, 'hdfc0001234xyz');
    expect(text(tester, 'IFSC code'), 'HDFC0001234');
    await tester.enterText(field, 'ab-12 !');
    expect(text(tester, 'IFSC code'), 'AB12');
  });
}
