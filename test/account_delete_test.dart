import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loothat_app/features/affiliate/profile/presentation/profile_providers.dart';
import 'package:loothat_app/features/legal/presentation/account_delete_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [profileProvider.overrideWith((ref) async => {'email': 'me@example.com'})],
      child: const MaterialApp(home: AccountDeleteScreen()),
    ));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the signed-in email as a read-only field', (tester) async {
    await pump(tester);
    final email = tester.widget<TextField>(find.widgetWithText(TextField, 'me@example.com'));
    expect(email.readOnly, isTrue);
    await tester.enterText(find.widgetWithText(TextField, 'me@example.com'), 'other@example.com');
    await tester.pump();
    expect(find.text('other@example.com'), findsNothing);
    expect(find.text('me@example.com'), findsOneWidget);
  });

  testWidgets('reason is mandatory', (tester) async {
    await pump(tester);
    await tester.ensureVisible(find.text('Submit deletion request'));
    await tester.tap(find.text('Submit deletion request'));
    await tester.pump();
    expect(find.text('Reason is required'), findsOneWidget);
  });
}
