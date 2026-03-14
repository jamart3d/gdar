import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:mockito/mockito.dart';

import 'screens/splash_screen_test.mocks.dart';

void main() {
  late MockSettingsProvider mockSettings;
  late MockAudioProvider mockAudio;

  setUp(() {
    mockSettings = MockSettingsProvider();
    mockAudio = MockAudioProvider();

    when(mockSettings.performanceMode).thenReturn(false);
    when(mockAudio.isPlaying).thenReturn(false);
  });

  Widget createTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: mockSettings),
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudio),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('AnimatedGradientBorder preserves size when showGlow is toggled',
      (WidgetTester tester) async {
    const double borderWidth = 4.0;
    const double childSize = 100.0;

    await tester.pumpWidget(
      createTestableWidget(
        const Center(
          child: AnimatedGradientBorder(
            borderWidth: borderWidth,
            showGlow: true,
            usePadding: true,
            child: SizedBox(width: childSize, height: childSize),
          ),
        ),
      ),
    );

    // Initial size with glow ON
    final Finder borderFinder = find.byType(AnimatedGradientBorder);
    final Size sizeWithGlow = tester.getSize(borderFinder);

    // Total size should be childSize + 2 * borderWidth
    expect(sizeWithGlow.width, childSize + 2 * borderWidth);
    expect(sizeWithGlow.height, childSize + 2 * borderWidth);

    // Toggle glow OFF
    await tester.pumpWidget(
      createTestableWidget(
        const Center(
          child: AnimatedGradientBorder(
            borderWidth: borderWidth,
            showGlow: false,
            usePadding: true,
            child: SizedBox(width: childSize, height: childSize),
          ),
        ),
      ),
    );

    final Size sizeWithoutGlow = tester.getSize(borderFinder);

    expect(sizeWithoutGlow, sizeWithGlow,
        reason:
            'Size should not change when showGlow is toggled if usePadding is true');
  });
}
