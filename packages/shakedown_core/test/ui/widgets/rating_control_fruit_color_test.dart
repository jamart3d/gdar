import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/rating_control.dart';

const Color _expectedFruitRatingYellow = Color(0xFFFFC107);
const Color _testThemePrimary = Color(0xFF00BFA5);

class _TestSettingsProvider extends ChangeNotifier implements SettingsProvider {
  _TestSettingsProvider({this.useNeumorphismValue = false});

  final bool useNeumorphismValue;

  @override
  bool get useNeumorphism => useNeumorphismValue;

  @override
  bool get useTrueBlack => false;

  @override
  bool get performanceMode => false;

  @override
  bool get fruitEnableLiquidGlass => true;

  @override
  bool get uiScale => false;

  @override
  bool get showDevAudioHud => false;

  @override
  bool get showPlaybackMessages => false;

  @override
  String get appFont => 'default';

  @override
  String get activeAppFont => 'default';

  @override
  bool get oilTvPremiumHighlight => false;

  @override
  bool get isTv => false;

  @override
  bool get highlightPlayingWithRgb => false;

  @override
  double get rgbAnimationSpeed => 1.0;

  @override
  NeumorphicStyle get neumorphicStyle => NeumorphicStyle.convex;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  ThemeStyle get themeStyle => ThemeStyle.fruit;

  @override
  bool get isFruit => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestAudioProvider extends ChangeNotifier implements AudioProvider {
  @override
  bool get isPlaying => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _buildTestApp(Widget child, {bool useNeumorphism = false}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>(
        create: (_) =>
            _TestSettingsProvider(useNeumorphismValue: useNeumorphism),
      ),
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => _TestThemeProvider(),
      ),
      ChangeNotifierProvider<DeviceService>(
        create: (_) => _TestDeviceService(),
      ),
      ChangeNotifierProvider<AudioProvider>(
        create: (_) => _TestAudioProvider(),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _testThemePrimary),
      ),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

List<Icon> _fruitStarIcons(WidgetTester tester) {
  return tester
      .widgetList<Icon>(
        find.byWidgetPredicate(
          (widget) => widget is Icon && widget.icon == Icons.star_rate_rounded,
        ),
      )
      .toList();
}

void main() {
  testWidgets(
    'Fruit rating control uses fixed yellow instead of theme primary',
    (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          const RatingControl(rating: 2, compact: true),
          useNeumorphism: true,
        ),
      );

      final starIcons = _fruitStarIcons(tester);
      final yellowCount = starIcons
          .where((icon) => icon.color == _expectedFruitRatingYellow)
          .length;
      final primaryCount = starIcons
          .where((icon) => icon.color == _testThemePrimary)
          .length;

      expect(yellowCount, 2);
      expect(primaryCount, 0);
    },
  );

  testWidgets(
    'Fruit rating dialog uses fixed yellow instead of theme primary',
    (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(1400, 1600);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          RatingDialog(
            initialRating: 2,
            isPlayed: false,
            onRatingChanged: (_) {},
          ),
          useNeumorphism: true,
        ),
      );

      final starIcons = _fruitStarIcons(tester);
      final yellowCount = starIcons
          .where((icon) => icon.color == _expectedFruitRatingYellow)
          .length;
      final primaryCount = starIcons
          .where((icon) => icon.color == _testThemePrimary)
          .length;

      expect(yellowCount, 2);
      expect(primaryCount, 0);
    },
  );
}
