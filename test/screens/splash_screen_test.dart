import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/providers/show_list_provider.dart';
import 'package:gdar/ui/screens/splash_screen.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'splash_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ShowListProvider>(),
  MockSpec<SettingsProvider>(),
  MockSpec<AudioProvider>()
])
void main() {
  late MockShowListProvider mockShowListProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockAudioProvider mockAudioProvider;

  setUp(() {
    mockShowListProvider = MockShowListProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockAudioProvider = MockAudioProvider();

    when(mockSettingsProvider.isFirstRun).thenReturn(false);
    when(mockSettingsProvider.showSplashScreen).thenReturn(true);
    when(mockSettingsProvider.playRandomOnStartup).thenReturn(false);
    when(mockSettingsProvider.useSliverAppBar).thenReturn(false);
    when(mockSettingsProvider.uiScale).thenReturn(false);
    when(mockSettingsProvider.useDynamicColor).thenReturn(true);
    when(mockSettingsProvider.glowMode).thenReturn(0);
    when(mockSettingsProvider.useTrueBlack).thenReturn(false);
    when(mockSettingsProvider.highlightCurrentShowCard).thenReturn(true);
    when(mockShowListProvider.isLoading).thenReturn(false);
    when(mockShowListProvider.allShows).thenReturn([]);
    when(mockShowListProvider.filteredShows).thenReturn([]);
    when(mockShowListProvider.totalShnids).thenReturn(0);
    when(mockShowListProvider.error).thenReturn(null);
    when(mockShowListProvider.expandedShowKey).thenReturn(null);
    when(mockShowListProvider.loadingShowKey).thenReturn(null);
    // Simulate check completed but failed
    when(mockShowListProvider.hasCheckedArchive).thenReturn(true);
    when(mockShowListProvider.isArchiveReachable).thenReturn(false);

    // Stub AudioProvider streams and properties
    when(mockAudioProvider.playerStateStream)
        .thenAnswer((_) => const Stream.empty());
    when(mockAudioProvider.currentShow).thenReturn(null);
    when(mockAudioProvider.currentSource).thenReturn(null);
    when(mockAudioProvider.error).thenReturn(null);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ShowListProvider>.value(
            value: mockShowListProvider),
        ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider),
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
      ],
      child: const MaterialApp(
        home: SplashScreen(),
      ),
    );
  }

  testWidgets('SplashScreen navigates away even if archive is unreachable',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(seconds: 3)); // Wait for min timer
    await tester.pumpAndSettle(); // Wait for animations and navigation

    // SplashScreen should be gone (navigated away)
    expect(find.byType(SplashScreen), findsNothing);
    // Should find ShowListScreen (but we need to ensure it renders something identifiable or just check SplashScreen is gone)
    // Since we didn't mock ShowListScreen's dependencies fully, it might crash if it tries to render,
    // but we just want to verify navigation happened.
    // Actually, ShowListScreen requires ShowListProvider which we mocked.
    // But ShowListScreen might have other dependencies.
    // Let's just check SplashScreen is gone.
  });
}
