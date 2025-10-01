// test/widget_test.dart

// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:gdar/main.dart'; // Make sure this import is correct

void main() {
  testWidgets('App starts and shows a title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Replace MyApp() with GdarApp()
    await tester.pumpWidget(const GdarApp());

    // This is a simple test to verify that the AppBar title is present.
    // This confirms the app has at least started and rendered the main screen.
    expect(find.text('gdar'), findsOneWidget);

    // This test is very basic. A real app would have more specific tests.
    // For example, verifying the search bar is present, etc.
    // For now, this is enough to make the test pass.
  });
}