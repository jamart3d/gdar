import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown/main.dart';
import 'package:shakedown/ui/screens/onboarding_screen.dart';
import 'package:shakedown/ui/widgets/tv/tv_dual_pane_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown/providers/show_list_provider.dart';

void main() {
  group('Onboarding Skip Logic', () {
    late SharedPreferences prefs;
    late ShowListProvider showListProvider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'show_onboarding': true,
        'show_splash_screen': false,
      });
      prefs = await SharedPreferences.getInstance();
      showListProvider = ShowListProvider();
    });

    testWidgets('shows OnboardingScreen when isTv is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(GdarApp(
        prefs: prefs,
        isTv: false,
        showListProvider: showListProvider,
      ));

      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(OnboardingScreen), findsOneWidget);
    });

    testWidgets('skips OnboardingScreen when isTv is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(GdarApp(
        prefs: prefs,
        isTv: true,
        showListProvider: showListProvider,
      ));

      await tester.pump(const Duration(seconds: 1));

      // Should NOT show onboarding
      expect(find.byType(OnboardingScreen), findsNothing);

      // Should show TV layout
      expect(find.byType(TvDualPaneLayout), findsOneWidget);
    });
  });
}
