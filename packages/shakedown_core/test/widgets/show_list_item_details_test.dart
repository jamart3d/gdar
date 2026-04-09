import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/models/rating.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/rating_control.dart';
import 'package:shakedown_core/ui/widgets/show_list_item_details.dart';

import '../helpers/fake_settings_provider.dart';
import '../screens/splash_screen_test.mocks.dart';

class MockCatalogService extends Mock implements CatalogService {
  @override
  ValueListenable<Box<Rating>> get ratingsListenable =>
      ValueNotifier(MockBox<Rating>());

  @override
  ValueListenable<Box<bool>> get historyListenable =>
      ValueNotifier(MockBox<bool>());

  @override
  ValueListenable<Box<int>> get playCountsListenable =>
      ValueNotifier(MockBox<int>());

  @override
  int getRating(String sourceId) => 0;

  @override
  bool isPlayed(String sourceId) => false;
}

class FakeDeviceService extends ChangeNotifier implements DeviceService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool get isTv => false;
}

class MockBox<T> extends Mock implements Box<T> {
  @override
  T? get(dynamic key, {T? defaultValue}) => defaultValue;
}

void main() {
  late MockAudioProvider mockAudioProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockAudioProvider = MockAudioProvider();
    CatalogService.setMock(MockCatalogService());

    when(mockAudioProvider.isPlaying).thenReturn(false);
    when(mockAudioProvider.currentShow).thenReturn(null);
    when(mockAudioProvider.currentSource).thenReturn(null);
  });

  Show createDummyShow(String name, {int sourceCount = 2}) {
    return Show(
      name: name,
      artist: 'Grateful Dead',
      date: '2025-01-01',
      venue: 'Venue',
      sources: List.generate(
        sourceCount,
        (i) => Source(id: 'source$i', tracks: []),
      ),
      hasFeaturedTrack: false,
    );
  }

  Widget createTestableWidget({
    required Show show,
    SettingsProvider? settingsProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider(
          create: (_) => settingsProvider ?? FakeSettingsProvider(),
        ),
        ChangeNotifierProvider<ShowListProvider>.value(
          value: MockShowListProvider(),
        ),
        ChangeNotifierProvider<DeviceService>(
          create: (_) => FakeDeviceService(),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ShowListItemDetails(
            show: show,
            playingSourceId: null,
            onSourceTapped: (_) {},
            onSourceLongPress: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('renders one source row and rating control per source', (
    WidgetTester tester,
  ) async {
    final show = createDummyShow('Show A', sourceCount: 2);

    await tester.pumpWidget(createTestableWidget(show: show));

    expect(find.text('source0'), findsOneWidget);
    expect(find.text('source1'), findsOneWidget);
    expect(find.byType(RatingControl), findsNWidgets(2));
  });

  testWidgets('does not render details for single-source shows', (
    WidgetTester tester,
  ) async {
    final show = createDummyShow('Solo Show', sourceCount: 1);

    await tester.pumpWidget(createTestableWidget(show: show));

    expect(find.byType(ShowListItemDetails), findsOneWidget);
    expect(find.byType(RatingControl), findsNothing);
    expect(find.text('source0'), findsNothing);
  });
}
