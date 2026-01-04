import 'package:flutter_test/flutter_test.dart';

import 'package:sk58_printer_example/main.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const Sk58PrinterExampleApp());

    // Verify that the app title is present
    expect(find.text('SK58 Printer'), findsOneWidget);
  });
}
