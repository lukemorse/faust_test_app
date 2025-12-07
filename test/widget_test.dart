import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:faust_test_app/main.dart';

void main() {
  testWidgets('renders Faust control surface', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Faust Engine Demo'), findsOneWidget);
    expect(find.text('Initialize'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);

    expect(find.text('Parameter controls'), findsOneWidget);
    expect(find.text('Address'), findsOneWidget);
    expect(find.widgetWithText(TextField, '0.5'), findsOneWidget);

    // Status chips should default to inactive on first render.
    expect(find.text('Initialized'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
  });
}
