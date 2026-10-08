import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loothat_app/core/widgets/common.dart';

void main() {
  testWidgets('AnimatedCount counts up over time', (tester) async {
    await tester.pumpWidget(MaterialApp(home: AnimatedCount(value: 1000, format: (n) => n.round().toString())));
    final t0 = tester.widget<Text>(find.byType(Text)).data;
    await tester.pump(const Duration(milliseconds: 300));
    final t1 = tester.widget<Text>(find.byType(Text)).data;
    await tester.pump(const Duration(milliseconds: 1000));
    final t2 = tester.widget<Text>(find.byType(Text)).data;
    expect(int.parse(t0!), lessThan(int.parse(t1!)));
    expect(int.parse(t1), lessThan(1000));
    expect(t2, '1000');
  });

  testWidgets('AnimatedCount is instant when reduce-motion is on', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: AnimatedCount(value: 1000, format: (n) => n.round().toString()),
      ),
    ));
    expect(tester.widget<Text>(find.byType(Text)).data, '1000');
  });

  testWidgets('Hero glows drift (transform changes between frames)', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox(width: 300, height: 300, child: Stack(children: [Positioned.fill(child: DecorativeOrbs())]))));
    double dx() {
      final t = tester.widgetList<Transform>(find.descendant(of: find.byType(DecorativeOrbs), matching: find.byType(Transform))).first;
      return t.transform.getTranslation().x;
    }

    await tester.pump(const Duration(milliseconds: 100));
    final a = dx();
    await tester.pump(const Duration(seconds: 3));
    final b = dx();
    expect(a, isNot(b));
  });
}
