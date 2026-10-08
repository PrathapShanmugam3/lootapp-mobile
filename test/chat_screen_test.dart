import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loothat_app/core/widgets/chat_message.dart';
import 'package:loothat_app/features/affiliate/chat/presentation/chat_providers.dart';
import 'package:loothat_app/features/affiliate/chat/presentation/chat_screen.dart';

final sent = <(String, XFile?)>[];

class _FakeChat extends ChatNotifier {
  @override
  Future<ChatState> build() async => const ChatState(status: 'open', messages: [
        ChatMessageModel(id: 1, from: 'admin', text: 'Hello', time: '10:00'),
      ]);

  @override
  Future<void> send(String text, {XFile? image}) async => sent.add((text, image));

  @override
  Future<void> poll() async {}
}

void main() {
  Future<void> pump(WidgetTester tester) async {
    sent.clear();
    await tester.pumpWidget(ProviderScope(
      overrides: [chatProvider.overrideWith(_FakeChat.new)],
      child: const MaterialApp(home: ChatScreen()),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('preset quick replies are gone', (tester) async {
    await pump(tester);
    for (final t in ['Payout delayed', 'Tracking issue', 'KYC help']) {
      expect(find.text(t), findsNothing);
    }
  });

  testWidgets('has attach button and sends typed text', (tester) async {
    await pump(tester);
    expect(find.byTooltip('Attach a picture'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'my payout is late');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(sent.single.$1, 'my payout is late');
    expect(sent.single.$2, isNull);
  });

  testWidgets('attach button opens gallery option', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Attach a picture'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Choose from gallery'), findsOneWidget);
  });
}
