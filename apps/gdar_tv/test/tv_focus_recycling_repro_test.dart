@Skip('Moved to packages/shakedown_core/test during monorepo transition')
library;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:mockito/mockito.dart';
import 'package:shakedown_core/ui/widgets/animated_gradient_border.dart';

class MockSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  bool get oilTvPremiumHighlight => true;
  @override
  double get rgbAnimationSpeed => 1.0;
  @override
  bool get isTv => true;
  @override
  bool get performanceMode => false;
  @override
  bool get highlightPlayingWithRgb => false;
  @override
  bool get highlightCurrentShowCard => false;
  @override
  bool get oilAutoTextSpacing => false;
  @override
  Future<void> setOilAutoTextSpacing(bool value) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAudioProvider extends ChangeNotifier implements AudioProvider {
  @override
  bool get isPlaying => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDeviceService extends Mock implements DeviceService {
  @override
  bool get isTv => true;
}

void main() {
  Provider.debugCheckInvalidValueType = null;
  testWidgets('TvFocusWrapper should sync focus state when recycled in a list', (
    WidgetTester tester,
  ) async {
    final List<FocusNode> nodes = List.generate(20, (index) => FocusNode());
    final settingsProvider = MockSettingsProvider();
    final deviceService = MockDeviceService();
    final audioProvider = MockAudioProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SettingsProvider>.value(value: settingsProvider),
          Provider<DeviceService>.value(value: deviceService),
          Provider<AudioProvider>.value(value: audioProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: 20,
                itemExtent: 100,
                itemBuilder: (context, index) {
                  return TvFocusWrapper(
                    focusNode: nodes[index],
                    child: Text('Item $index'),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    // 1. Focus the first item
    nodes[0].requestFocus();
    await tester.pump(); // Start focus change
    await tester.pump(const Duration(milliseconds: 300)); // Wait for animations

    // Verify item 0 is focused and has the premium highlight (AnimatedGradientBorder with non-zero width)
    expect(find.text('Item 0'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is AnimatedGradientBorder && widget.borderWidth > 0,
      ),
      findsOneWidget,
    );

    // 2. Scroll down so Item 0 is off-screen
    final scrollable = find.byType(Scrollable);
    await tester.drag(
      scrollable,
      const Offset(0, -1000),
    ); // Scroll way down (10 items)
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Item 0 is definitely off-screen now.
    expect(find.text('Item 0'), findsNothing);

    // There should be NO AnimatedGradientBorder with a non-zero border width visible
    // because none of the visible items are focused.
    expect(
      find.byWidgetPredicate(
        (widget) => widget is AnimatedGradientBorder && widget.borderWidth > 0,
      ),
      findsNothing,
      reason:
          'Recycled items should not retain highlight if their current node is not focused',
    );
  });
}

