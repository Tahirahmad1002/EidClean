import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eidclean_app/main.dart';

void main() {
  testWidgets('EidClean app loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EidCleanApp());

    // Verify the app renders without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
