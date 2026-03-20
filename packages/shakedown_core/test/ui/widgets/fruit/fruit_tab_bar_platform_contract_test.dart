import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/fruit_tab_bar.dart';
import 'package:shakedown_core/ui/widgets/theme/liquid_glass_wrapper.dart';

// ─── Minimal fakes ──────────────────────────────────────────────────────────

class _FakeSettings extends ChangeNotifier implements SettingsProvider {
  _FakeSettings({
    this.fruitEnableLiquidGlass = true,
    this.useTrueBlack = false,
  });

  @override
  final bool fruitEnableLiquidGlass;
  @override
  final bool useTrueBlack;
  @override
  bool get uiScale => false;
  @override
  String get appFont => 'default';
  @override
  bool get nonRandom => false;
  @override
  bool get simpleRandomIcon => false;
  @override
  bool get enableHaptics => false;
  @override
  bool get performanceMode => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => false;
  @override
  bool get isMobile => true;
  @override
  bool get isDesktop => false;
  @override
  bool get isSafari => false;
  @override
  bool get isPwa => false;
  @override
  String? get deviceName => 'Test';
  @override
  Future<void> refresh() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTheme extends ChangeNotifier implements ThemeProvider {
  _FakeTheme({this.style = ThemeStyle.fruit});
  final ThemeStyle style;

  @override
  ThemeStyle get themeStyle => style;
  @override
  bool get isDarkMode => false;
  @override
  bool get isFruitAllowed => true;
  @override
  Future<void> get initializationComplete => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAudio extends ChangeNotifier implements AudioProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeShowList extends ChangeNotifier implements ShowListProvider {
  @override
  bool get isChoosingRandomShow => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ─── Helper ─────────────────────────────────────────────────────────────────

Widget _wrap(
  Widget child,
  _FakeSettings settings, {
  ThemeStyle style = ThemeStyle.fruit,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(value: settings),
      ChangeNotifierProvider<ThemeProvider>.value(
        value: _FakeTheme(style: style),
      ),
      ChangeNotifierProvider<AudioProvider>.value(value: _FakeAudio()),
      ChangeNotifierProvider<ShowListProvider>.value(value: _FakeShowList()),
      ChangeNotifierProvider<DeviceService>.value(value: _FakeDeviceService()),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('FruitTabBar — LiquidGlassWrapper never rendered on non-web', () {
    // kIsWeb = false in all unit tests, so every case exercises the phone path.

    testWidgets('liquid glass ON + Fruit theme → no LiquidGlassWrapper', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          FruitTabBar(selectedIndex: 0, onTabSelected: (_) {}),
          _FakeSettings(fruitEnableLiquidGlass: true, useTrueBlack: false),
        ),
      );

      expect(find.byType(LiquidGlassWrapper), findsNothing);
    });

    testWidgets('true black mode → no LiquidGlassWrapper', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FruitTabBar(selectedIndex: 0, onTabSelected: (_) {}),
          _FakeSettings(fruitEnableLiquidGlass: true, useTrueBlack: true),
        ),
      );

      expect(find.byType(LiquidGlassWrapper), findsNothing);
    });

    testWidgets('liquid glass OFF → no LiquidGlassWrapper', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FruitTabBar(selectedIndex: 0, onTabSelected: (_) {}),
          _FakeSettings(fruitEnableLiquidGlass: false, useTrueBlack: false),
        ),
      );

      expect(find.byType(LiquidGlassWrapper), findsNothing);
    });

    testWidgets('non-Fruit theme → no LiquidGlassWrapper', (tester) async {
      await tester.pumpWidget(
        _wrap(
          FruitTabBar(selectedIndex: 0, onTabSelected: (_) {}),
          _FakeSettings(fruitEnableLiquidGlass: true, useTrueBlack: false),
          style: ThemeStyle.android,
        ),
      );

      expect(find.byType(LiquidGlassWrapper), findsNothing);
    });
  });
}
