// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown/main.dart';

void main() {
  testWidgets('App starts and shows a title', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final showListProvider = ShowListProvider();

    await tester.pumpWidget(GdarApp(
      prefs: prefs,
      showListProvider: showListProvider,
    ));

    expect(find.text('Shakedown'), findsOneWidget);
  });
}
