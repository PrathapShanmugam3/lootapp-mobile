import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loothat_app/core/widgets/confirm_dialog.dart';

void main() {
  Future<bool?> run(WidgetTester tester, String tap) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async => result = await confirmLogout(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Log out?'), findsOneWidget);
    await tester.tap(find.text(tap));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    return result;
  }

  testWidgets('Cancel returns false', (tester) async {
    expect(await run(tester, 'Cancel'), isFalse);
  });

  testWidgets('Log out returns true', (tester) async {
    expect(await run(tester, 'Log out'), isTrue);
  });
}
