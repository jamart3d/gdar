import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/hud_snapshot.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/ui/widgets/playback/dev_audio_hud.dart';

import '../../../helpers/fake_settings_provider.dart';

class _FakeAudioProvider extends ChangeNotifier implements AudioProvider {
  _FakeAudioProvider(this._snapshot);

  HudSnapshot _snapshot;
  final StreamController<HudSnapshot> _controller =
      StreamController<HudSnapshot>.broadcast();

  @override
  Stream<HudSnapshot> get hudSnapshotStream => _controller.stream;

  @override
  HudSnapshot get currentHudSnapshot => _snapshot;

  void emit(HudSnapshot snapshot) {
    _snapshot = snapshot;
    _controller.add(snapshot);
    notifyListeners();
  }

  Future<void> disposeStream() => _controller.close();

  @override
  void clearLastIssue() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAudioProvider audioProvider;
  late FakeSettingsProvider settingsProvider;

  Widget createWidget({bool isAppVisible = true}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(isTv: false),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: DevAudioHud(
            audioProvider: audioProvider,
            settingsProvider: settingsProvider,
            labelsFontSize: 12,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            fontFamily: 'RobotoMono',
            compact: true,
            isAppVisible: isAppVisible,
          ),
        ),
      ),
    );
  }

  setUp(() {
    settingsProvider = FakeSettingsProvider();
    settingsProvider.showDevAudioHud = true;
    final initialHud = HudSnapshot.empty().copyWith(
      engine: 'HYB',
      activeEngine: 'WA',
      isPlaying: true,
    );
    audioProvider = _FakeAudioProvider(initialHud);
  });

  tearDown(() async {
    await audioProvider.disposeStream();
  });

  testWidgets('renders state and WA telemetry chips from the snapshot', (
    tester,
  ) async {
    audioProvider.emit(
      HudSnapshot.empty().copyWith(
        engine: 'WBA',
        activeEngine: 'WA',
        visibility: 'VIS(0m)',
        processing: 'RDY',
        engineState: 'ACT',
        isPlaying: true,
        scheduledIndex: 2,
        scheduledStartContextTime: 14.5,
        ctxCurrentTime: 12.0,
        outputLatencyMs: 45.6,
        lastDecodeMs: 78.9,
        lastConcatMs: 12.3,
        failedTrackCount: 2,
        workerTickCount: 10,
        sampleRate: 48000,
        decodedCacheSize: 3,
      ),
    );

    await tester.pumpWidget(createWidget());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('AE:'), findsOneWidget);
    expect(find.text('PS:'), findsOneWidget);
    expect(find.text('ST:'), findsOneWidget);
    expect(find.text('SHD:'), findsOneWidget);
    expect(find.text('GAP:'), findsOneWidget);
    expect(find.text('PM:'), findsOneWidget);
    expect(find.text('LAT:'), findsOneWidget);
    expect(find.text('ERR:'), findsOneWidget);
    expect(find.text('WTC:'), findsOneWidget);
    expect(find.text('SR:'), findsOneWidget);
    expect(find.text('CAC:'), findsOneWidget);
    expect(find.text('SCH:'), findsOneWidget);
    expect(find.text('DEC:'), findsOneWidget);
    expect(find.text('BCT:'), findsOneWidget);
  });

  testWidgets('hides WA-only telemetry while hybrid is on the H5B sub-engine', (
    tester,
  ) async {
    audioProvider.emit(
      HudSnapshot.empty().copyWith(
        engine: 'HYB',
        activeEngine: 'H5B',
        visibility: 'VIS(0m)',
        processing: 'RDY',
        engineState: 'ACT',
        handoffState: 'ARM',
        handoffAttemptCount: 2,
        lastHandoffPollCount: 4,
        isPlaying: true,
      ),
    );

    await tester.pumpWidget(createWidget());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('H5B'), findsOneWidget);
    expect(find.text('HF:'), findsOneWidget);
    expect(find.text('BG:'), findsOneWidget);
    expect(find.text('PF:'), findsOneWidget);
    expect(find.text('HS:'), findsOneWidget);
    expect(find.text('HAT:'), findsOneWidget);
    expect(find.text('HPD:'), findsNothing);
    expect(find.text('D:'), findsOneWidget);
    expect(find.text('TX:'), findsNothing);
    expect(find.text('LAT:'), findsNothing);
    expect(find.text('ERR:'), findsNothing);
    expect(find.text('WTC:'), findsNothing);
    expect(find.text('SR:'), findsNothing);
    expect(find.text('CAC:'), findsNothing);
    expect(find.text('SCH:'), findsNothing);
    expect(find.text('DEC:'), findsNothing);
    expect(find.text('BCT:'), findsNothing);
  });

  testWidgets('hides hybrid handoff telemetry when HF is OFF', (tester) async {
    audioProvider.emit(
      HudSnapshot.empty().copyWith(
        engine: 'HYB',
        activeEngine: 'H5B',
        handoff: 'OFF',
        handoffState: 'IDLE',
        handoffAttemptCount: 2,
        isPlaying: true,
      ),
    );

    await tester.pumpWidget(createWidget());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text('HF:'), findsOneWidget);
    expect(find.text('HS:'), findsNothing);
    expect(find.text('HAT:'), findsNothing);
  });

  testWidgets('reports pure H5 engine without B suffix', (tester) async {
    audioProvider.emit(
      HudSnapshot.empty().copyWith(
        engine: 'H5',
        activeEngine: 'H5',
        isPlaying: true,
      ),
    );

    await tester.pumpWidget(createWidget());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    // Expecting 2 widgets with text "H5": one for ENG and one for AE
    expect(find.text('H5'), findsNWidgets(2));
    expect(find.text('H5B'), findsNothing);
  });

  testWidgets(
    'LG chip shows -- when lastGapMs is null and value when not null',
    (tester) async {
      // 1. Null case
      audioProvider.emit(
        HudSnapshot.empty().copyWith(
          engine: 'HYB',
          activeEngine: 'WA',
          lastGapMs: null,
          isPlaying: true,
        ),
      );

      await tester.pumpWidget(createWidget());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.textContaining('LG:'), findsOneWidget);
      expect(find.textContaining('BUF:'), findsOneWidget);
      expect(find.textContaining('NX:'), findsOneWidget);
      expect(find.text('--'), findsAtLeastNWidgets(1));

      // 2. Value case
      audioProvider.emit(
        HudSnapshot.empty().copyWith(
          engine: 'HYB',
          activeEngine: 'WA',
          lastGapMs: 12.0,
          isPlaying: true,
        ),
      );

      await tester.pump();
      expect(find.textContaining('LG:'), findsOneWidget);
    },
  );

  testWidgets('BGT shows the current hidden duration only', (tester) async {
    audioProvider.emit(
      HudSnapshot.empty().copyWith(
        engine: 'HYB',
        activeEngine: 'WA',
        isPlaying: true,
      ),
    );

    await tester.pumpWidget(createWidget(isAppVisible: false));
    await tester.pump();

    expect(find.text('BGT:'), findsOneWidget);
    expect(find.text('00:00'), findsOneWidget);

    await tester.pumpWidget(createWidget(isAppVisible: true));
    await tester.pump();

    expect(find.text('BGT:'), findsOneWidget);
    expect(find.text('00:00'), findsNothing);
    expect(find.text('--'), findsAtLeastNWidgets(1));
  });

  testWidgets('shows tooltip text for sparkline chips', (tester) async {
    audioProvider.emit(
      HudSnapshot.empty().copyWith(
        engine: 'WBA',
        activeEngine: 'WA',
        isPlaying: true,
        scheduledIndex: 1,
        scheduledStartContextTime: 5.0,
        ctxCurrentTime: 4.0,
      ),
    );

    await tester.pumpWidget(createWidget());
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    await tester.longPress(find.text('DFT'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Tick drift sparkline. Lower and steadier is better.',
        findRichText: true,
      ),
      findsOneWidget,
    );
  });
}
