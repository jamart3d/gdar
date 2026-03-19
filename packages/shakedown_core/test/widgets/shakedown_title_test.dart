import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import '../helpers/fake_settings_provider.dart';
import 'package:shakedown_core/ui/widgets/shakedown_title.dart';

class _TitleSettingsProvider extends FakeSettingsProvider {
  @override
  String get appFont => 'default';

  @override
  String get activeAppFont => 'default';

  @override
  bool get enableShakedownTween => true;

  @override
  bool get useNeumorphism => false;
}

class _FakeDeviceService extends ChangeNotifier implements DeviceService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool get isTv => false;
}

void main() {
  late _TitleSettingsProvider settingsProvider;

  setUp(() {
    settingsProvider = _TitleSettingsProvider();
  });

  Widget createWidget({
    bool animateOnStart = false,
    Duration shakeDelay = Duration.zero,
    bool enableHero = false,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<DeviceService>.value(
          value: _FakeDeviceService(),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ShakedownTitle(
            fontSize: 20,
            enableHero: enableHero,
            animateOnStart: animateOnStart,
            shakeDelay: shakeDelay,
          ),
        ),
      ),
    );
  }

  testWidgets('renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidget());
    expect(find.text('Shakedown'), findsOneWidget);
  });

  testWidgets('respects shakeDelay and animates', (WidgetTester tester) async {
    const delay = Duration(seconds: 1);
    await tester.pumpWidget(
      createWidget(animateOnStart: true, shakeDelay: delay),
    );

    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  });
}
