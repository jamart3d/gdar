// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gdar_mobile/main.dart';

void main() {
  testWidgets('App starts and shows a title', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(GdarMobileApp(prefs: prefs, isTv: false));

    expect(find.text('Shakedown'), findsOneWidget);
  });
}
