import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import '../../../helpers/fake_settings_provider.dart';
import '../../../helpers/test_helpers.dart';
import 'package:shakedown_core/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';

class FakeAudioProvider extends ChangeNotifier implements AudioProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool get isPlaying => false;
}

void main() {
  late FakeSettingsProvider settingsProvider;
  late MockDeviceService deviceService;
  late FakeAudioProvider audioProvider;

  Widget buildHarness(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
        ChangeNotifierProvider<DeviceService>.value(value: deviceService),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  setUp(() {
    settingsProvider = FakeSettingsProvider()..isTv = true;
    deviceService = MockDeviceService()..isTv = true;
    audioProvider = FakeAudioProvider();
  });

  testWidgets('TvFocusWrapper does NOT trigger onTap on focus gain', (
    WidgetTester tester,
  ) async {
    bool tapped = false;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      buildHarness(
        TvFocusWrapper(
          focusNode: focusNode,
          onTap: () => tapped = true,
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    expect(tapped, isFalse);
  });

  testWidgets('TvFocusWrapper ignores key up without prior key down', (
    WidgetTester tester,
  ) async {
    int tapCount = 0;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      buildHarness(
        Column(
          children: [
            const Focus(autofocus: true, child: Text('Other Widget')),
            TvFocusWrapper(
              focusNode: focusNode,
              onTap: () => tapCount++,
              child: const Text('Focus Me'),
            ),
          ],
        ),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump();

    focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump();

    expect(tapCount, 0);
  });

  testWidgets('TvFocusWrapper triggers onTap on Select key up', (
    WidgetTester tester,
  ) async {
    bool tapped = false;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      buildHarness(
        TvFocusWrapper(
          focusNode: focusNode,
          onTap: () => tapped = true,
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();

    await simulateKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(tapped, isFalse);

    await simulateKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('TvFocusWrapper clears highlight when recycled in a list', (
    WidgetTester tester,
  ) async {
    final nodes = List.generate(20, (_) => FocusNode());
    addTearDown(() {
      for (final node in nodes) {
        node.dispose();
      }
    });

    await tester.pumpWidget(
      buildHarness(
        SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: 20,
            itemExtent: 100,
            itemBuilder: (context, index) {
              return TvFocusWrapper(
                focusNode: nodes[index],
                overridePremiumHighlight: true,
                child: Text('Item $index'),
              );
            },
          ),
        ),
      ),
    );

    nodes[0].requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byWidgetPredicate(
        (widget) => widget is AnimatedGradientBorder && widget.borderWidth > 0,
      ),
      findsOneWidget,
    );

    await tester.drag(find.byType(Scrollable), const Offset(0, -1000));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Item 0'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is AnimatedGradientBorder && widget.borderWidth > 0,
      ),
      findsNothing,
    );
  });
}


