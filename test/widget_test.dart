// Basic smoke test — verifies the app boots to the splash screen (the
// router's initial route while auth status is still AuthStatus.unknown)
// without throwing. Full auth/navigation flows need a mocked ApiClient and
// are out of scope for this placeholder.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loothat_app/main.dart';

void main() {
  testWidgets('App boots to splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LootHatApp()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
