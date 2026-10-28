import 'dart:async';
import 'package:driver_app/core/widgets/slide_to_accept.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    Future<void> Function() accept, {
    bool enabled = true,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          child: SlideToAccept(onAccept: accept, enabled: enabled),
        ),
      ),
    ),
  );

  testWidgets('partial drag does not accept and resets the handle', (
    tester,
  ) async {
    var accepted = 0;
    await mount(tester, () async {
      accepted++;
    });
    final handle = find.byIcon(Icons.keyboard_double_arrow_right);
    final original = tester.getCenter(handle);
    await tester.drag(handle, const Offset(100, 0));
    await tester.pump();
    expect(accepted, 0);
    expect(tester.getCenter(handle), original);
  });
  testWidgets('full slide accepts exactly once while the request is pending', (
    tester,
  ) async {
    var accepted = 0;
    final pending = Completer<void>();
    await mount(tester, () {
      accepted++;
      return pending.future;
    });
    await tester.drag(
      find.byIcon(Icons.keyboard_double_arrow_right),
      const Offset(280, 0),
    );
    await tester.pump();
    expect(accepted, 1);
    expect(find.text('Accepting…'), findsOneWidget);
    await tester.drag(
      find.byType(CircularProgressIndicator),
      const Offset(-280, 0),
    );
    await tester.pump();
    expect(accepted, 1);
    pending.complete();
    await tester.pump();
    expect(find.text('Slide to accept'), findsOneWidget);
  });
  testWidgets('disabled or expired offers cannot be accepted', (tester) async {
    var accepted = 0;
    await mount(tester, () async {
      accepted++;
    }, enabled: false);
    await tester.drag(
      find.byIcon(Icons.keyboard_double_arrow_right),
      const Offset(280, 0),
    );
    await tester.pump();
    expect(accepted, 0);
  });
}
