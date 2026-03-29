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

  Widget createWidget() {
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
          ),
        ),
      ),
    );
  }

  setUp(() {
    settingsProvider = FakeSettingsProvider();
    audioProvider = _FakeAudioProvider(HudSnapshot.empty());
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

  testWidgets('hides WA-only telemetry while hybrid is on the H5 sub-engine', (
    tester,
  ) async {
    audioProvider.emit(
      HudSnapshot.empty().copyWith(
        engine: 'HYB',
        activeEngine: 'H5',
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
    await tester.pump();

    expect(find.text('HF:'), findsOneWidget);
    expect(find.text('BG:'), findsOneWidget);
    expect(find.text('PF:'), findsOneWidget);
    expect(find.text('HS:'), findsOneWidget);
    expect(find.text('HAT:'), findsOneWidget);
    expect(find.text('HPD'), findsOneWidget);
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
