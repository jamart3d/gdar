// Regression test for:
// Race condition: tapping Library while _selectTab(2) is awaiting playRandomShow()
// caused _jumpToPlayTabImmediate() to fire after the user had already navigated away,
// forcing them back to the PLAY tab.
//
// Fix: _jumpToPlayTabImmediate() is now guarded by `_selectedTab == 2`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/providers/update_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/ui/screens/fruit_tab_host_screen.dart';
import 'package:shakedown_core/ui/widgets/fruit_tab_bar.dart';

import '../../helpers/fake_settings_provider.dart';
import '../../helpers/test_helpers.dart';

// AudioProvider whose playRandomShow() hangs until completeRandomPlay() is called.
class _SlowAudioProvider extends ChangeNotifier implements AudioProvider {
  final _randomShowRequestController =
      StreamController<({Show show, Source source})>.broadcast();

  Completer<Show?>? _completer;
  int playRandomShowCallCount = 0;

  void completeRandomPlay() => _completer?.complete(null);

  @override
  Stream<({Show show, Source source})> get randomShowRequestStream =>
      _randomShowRequestController.stream;

  @override
  Future<Show?> playRandomShow({
    bool filterBySearch = true,
    bool animationOnly = false,
    bool delayPlayback = false,
  }) async {
    playRandomShowCallCount++;
    _completer = Completer<Show?>();
    return _completer!.future;
  }

  @override
  ({Show show, Source source})? get pendingRandomShowRequest => null;
  @override
  void clearPendingRandomShowRequest() {}
  @override
  Show? get currentShow => null;
  @override
  Source? get currentSource => null;
  @override
  Track? get currentTrack => null;
  @override
  bool get isPlaying => false;
  @override
  String? get error => null;
  @override
  int get cachedTrackCount => 0;
  @override
  Stream<String> get playbackErrorStream => const Stream.empty();
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration> get bufferedPositionStream => const Stream.empty();
  @override
  Stream<int?> get currentIndexStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<void> get playbackFocusRequestStream => const Stream.empty();
  @override
  Stream<String> get notificationStream => const Stream.empty();
  @override
  Stream<({String message, VoidCallback? retryAction})>
  get bufferAgentNotificationStream => const Stream.empty();
  @override
  late final GaplessPlayer audioPlayer = GaplessPlayer();
  @override
  void update(ShowListProvider slp, SettingsProvider sp, dynamic acs) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  ThemeStyle get themeStyle => ThemeStyle.fruit;
  @override
  bool get isFruit => true;
  @override
  bool get isFruitAllowed => true;
  @override
  ThemeMode get currentThemeMode => ThemeMode.dark;
  @override
  ThemeMode get selectedThemeMode => currentThemeMode;
  @override
  bool get isDarkMode => true;
  @override
  FruitColorOption get fruitColorOption => FruitColorOption.sophisticate;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeShowListProvider extends ChangeNotifier implements ShowListProvider {
  bool _isChoosing = false;

  @override
  bool get isLoading => false;
  @override
  String? get error => null;
  @override
  bool get isChoosingRandomShow => _isChoosing;
  @override
  void setIsChoosingRandomShow(bool value) {
    _isChoosing = value;
    notifyListeners();
  }

  @override
  List<Show> get allShows => [];
  @override
  List<Show> get filteredShows => [];
  @override
  Set<String> get availableCategories => {};
  @override
  bool get isSearchVisible => false;
  @override
  bool get hasUsedRandomButton => true;
  @override
  Future<void> get initializationComplete => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUpdateProvider extends ChangeNotifier implements UpdateProvider {
  @override
  bool get isSimulated => false;
  @override
  Null get updateInfo => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HostSettingsProvider extends FakeSettingsProvider {
  _HostSettingsProvider({
    this.isCarMode = false,
    this.hasLiquidGlass = false,
    this.isPerformanceMode = false,
  });

  final bool isCarMode;
  final bool hasLiquidGlass;
  final bool isPerformanceMode;

  @override
  bool get carMode => isCarMode;

  @override
  bool get fruitEnableLiquidGlass => hasLiquidGlass;

  @override
  bool get performanceMode => isPerformanceMode;

  @override
  bool get fruitFloatingSpheres => false;
}

class _CarModeSettingsProvider extends _HostSettingsProvider {
  _CarModeSettingsProvider()
    : super(isCarMode: true, hasLiquidGlass: false, isPerformanceMode: false);

  @override
  bool get carMode => true;
}

void main() {
  testWidgets(
    'tapping Library during pending RANDOM play does not force PLAY tab',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final audioProvider = _SlowAudioProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: _HostSettingsProvider(),
            ),
            ChangeNotifierProvider<ShowListProvider>.value(
              value: _FakeShowListProvider(),
            ),
            ChangeNotifierProvider<ThemeProvider>.value(
              value: _FakeThemeProvider(),
            ),
            ChangeNotifierProvider<DeviceService>.value(
              value: MockDeviceService(),
            ),
            ChangeNotifierProvider<UpdateProvider>.value(
              value: _FakeUpdateProvider(),
            ),
          ],
          child: const MaterialApp(home: FruitTabHostScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Initial: Library tab selected (page 1, selectedIndex 1).
      FruitTabBar tabBar() =>
          tester.widget<FruitTabBar>(find.byType(FruitTabBar));
      expect(tabBar().selectedIndex, 1);

      // Step 1: Tap RANDOM — _selectTab(2) starts, playRandomShow() now hangs.
      await tester.tap(find.text('RANDOM'));
      await tester.pump(); // process tap, enter _selectTab(2), hit await
      expect(audioProvider.playRandomShowCallCount, 1);
      expect(tabBar().selectedIndex, 2); // RANDOM tab visually active

      // Step 2: User immediately taps Library before playRandomShow() resolves.
      await tester.tap(find.text('LIBRARY'));
      await tester.pump();
      expect(tabBar().selectedIndex, 1); // moved to Library

      // Step 3: playRandomShow() completes — guard must prevent jump to PLAY.
      audioProvider.completeRandomPlay();
      await tester.pump(); // completer resolves
      await tester.pump(
        const Duration(milliseconds: 150),
      ); // past guarded 100ms delay

      expect(
        tabBar().selectedIndex,
        1,
        reason:
            'User navigated to Library before random play resolved — '
            'should not be forced to Play tab',
      );

      // Drain the _scheduleRandomReset timer (2400ms when performanceMode=false).
      await tester.pump(const Duration(milliseconds: 2500));
    },
  );

  testWidgets(
    'car mode animates Fruit tab transitions even when liquid glass is off',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AudioProvider>.value(
              value: _SlowAudioProvider(),
            ),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: _CarModeSettingsProvider(),
            ),
            ChangeNotifierProvider<ShowListProvider>.value(
              value: _FakeShowListProvider(),
            ),
            ChangeNotifierProvider<ThemeProvider>.value(
              value: _FakeThemeProvider(),
            ),
            ChangeNotifierProvider<DeviceService>.value(
              value: MockDeviceService(),
            ),
            ChangeNotifierProvider<UpdateProvider>.value(
              value: _FakeUpdateProvider(),
            ),
          ],
          child: const MaterialApp(home: FruitTabHostScreen()),
        ),
      );

      await tester.pumpAndSettle();

      FruitTabBar tabBar() =>
          tester.widget<FruitTabBar>(find.byType(FruitTabBar));
      final scrollableState = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(PageView),
          matching: find.byType(Scrollable),
        ),
      );
      final pageHeight = tester.getSize(find.byType(PageView)).height;
      final initialPixels = scrollableState.position.pixels;

      expect(tabBar().selectedIndex, 1);
      expect(find.byType(PageView), findsOneWidget);
      expect(initialPixels, closeTo(pageHeight, 0.01));

      await tester.tap(find.text('SETTINGS'));
      await tester.pump();

      expect(
        tabBar().selectedIndex,
        3,
        reason: 'Selection should update immediately when the tab is tapped.',
      );
      expect(
        scrollableState.position.pixels,
        closeTo(initialPixels, 0.01),
        reason:
            'The first post-tap frame should not jump straight to the target page.',
      );

      await tester.pump(const Duration(milliseconds: 120));
      expect(scrollableState.position.pixels, greaterThan(initialPixels));
      expect(
        scrollableState.position.pixels,
        lessThan(pageHeight * 2),
        reason:
            'Car mode should animate toward settings instead of cutting instantly.',
      );

      await tester.pump(const Duration(milliseconds: 160));
      expect(scrollableState.position.pixels, closeTo(pageHeight * 2, 0.5));
    },
  );
}
