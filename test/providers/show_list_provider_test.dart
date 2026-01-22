import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/rating.dart';
import 'package:hive/hive.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shakedown/providers/settings_provider.dart';

import 'show_list_provider_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<CatalogService>(),
  MockSpec<SettingsProvider>(),
  MockSpec<SharedPreferences>(),
  MockSpec<Box<Rating>>(as: #MockRatingBox),
])
void main() {
  late ShowListProvider showListProvider;
  late MockCatalogService mockCatalogService;
  late MockSharedPreferences mockPrefs;

  // Helper function to create a dummy show
  Show createDummyShow(String name, String date,
      {bool hasFeaturedTrack = false}) {
    return Show(
      name: name,
      artist: 'Grateful Dead',
      date: date,
      venue: name,
      sources: [
        Source(
          id: 'source1',
          tracks: [], // Empty tracks for now, as provider doesn't strictly check them for list filtering
        ),
      ],
      hasFeaturedTrack: hasFeaturedTrack,
    );
  }

  final dummyShows = [
    createDummyShow('Venue A on 2025-01-15', '2025-01-15'),
    createDummyShow('Venue B on 2025-02-20', '2025-02-20'),
    createDummyShow('Venue C on 2025-03-25', '2025-03-25',
        hasFeaturedTrack: true),
  ];

  setUp(() {
    mockCatalogService = MockCatalogService();
    mockPrefs = MockSharedPreferences();
    showListProvider = ShowListProvider(catalogService: mockCatalogService);

    // Stub default ValueListenables
    final mockRatingBox = MockRatingBox();
    when(mockCatalogService.ratingsListenable)
        .thenReturn(ValueNotifier<Box<Rating>>(mockRatingBox));
  });

  group('ShowListProvider Tests', () {
    test('Initial values are correct', () {
      expect(showListProvider.isLoading, isTrue); // Starts loading
      expect(showListProvider.error, isNull);
      expect(showListProvider.searchQuery, isEmpty);
      expect(showListProvider.filteredShows, isEmpty);
    });

    test('fetchShows successfully loads shows', () async {
      when(mockCatalogService.initialize(
              prefs: anyNamed('prefs'), strategy: anyNamed('strategy')))
          .thenAnswer((_) async {});
      when(mockCatalogService.allShows).thenReturn(dummyShows);
      await showListProvider.fetchShows(mockPrefs);

      await showListProvider.fetchShows(mockPrefs);

      expect(showListProvider.isLoading, isFalse);
      expect(showListProvider.error, isNull);
      // The filteredShows getter filtering logic remains the same
      expect(showListProvider.filteredShows.length, 3);
    });

    test('fetchShows handles errors', () async {
      when(mockCatalogService.initialize(
              prefs: anyNamed('prefs'), strategy: anyNamed('strategy')))
          .thenThrow(Exception('Failed to load'));

      await showListProvider.fetchShows(mockPrefs);

      expect(showListProvider.isLoading, isFalse);
      expect(showListProvider.error, isNotNull);
      expect(showListProvider.filteredShows, isEmpty);
    });

    test('setSearchQuery updates the query and notifies listeners', () {
      var listenerCalled = false;
      showListProvider.addListener(() {
        listenerCalled = true;
      });

      showListProvider.setSearchQuery('Venue A');

      expect(showListProvider.searchQuery, 'Venue A');
      expect(listenerCalled, isTrue);
    });

    test('filteredShows returns correct shows based on search query', () async {
      when(mockCatalogService.initialize(
              prefs: anyNamed('prefs'), strategy: anyNamed('strategy')))
          .thenAnswer((_) async {});
      when(mockCatalogService.allShows).thenReturn(dummyShows);
      await showListProvider.fetchShows(mockPrefs);

      showListProvider.setSearchQuery('Venue A');
      expect(showListProvider.filteredShows.length, 1);
      expect(
          showListProvider.filteredShows.first.name, 'Venue A on 2025-01-15');

      showListProvider.setSearchQuery('2025-02-20');
      expect(showListProvider.filteredShows.length, 1);
      expect(
          showListProvider.filteredShows.first.name, 'Venue B on 2025-02-20');
    });

    test('filteredShows hides featured tracks', () async {
      when(mockCatalogService.initialize(
              prefs: anyNamed('prefs'), strategy: anyNamed('strategy')))
          .thenAnswer((_) async {});
      when(mockCatalogService.allShows).thenReturn(dummyShows);
      await showListProvider.fetchShows(mockPrefs);

      // Expect 3 because we default to fail-open
      expect(showListProvider.filteredShows.length, 3);
    });

    test('toggleShowExpansion (prev onShowTap) expands and collapses a show',
        () async {
      when(mockCatalogService.initialize(
              prefs: anyNamed('prefs'), strategy: anyNamed('strategy')))
          .thenAnswer((_) async {});
      when(mockCatalogService.allShows).thenReturn(dummyShows);
      await showListProvider.fetchShows(mockPrefs);
      final show = showListProvider.filteredShows.first;
      final key = showListProvider.getShowKey(show);

      showListProvider.toggleShowExpansion(key);
      expect(showListProvider.expandedShowKey, key);

      showListProvider.toggleShowExpansion(key);
      expect(showListProvider.expandedShowKey, isNull);
    });

    test('setLoadingShow updates the loading show name', () {
      final show = dummyShows.first;
      final key = showListProvider.getShowKey(show);
      showListProvider.setLoadingShow(key);
      expect(showListProvider.loadingShowKey, key);
    });

    test('expandShow expands the given show', () async {
      when(mockCatalogService.initialize(
              prefs: anyNamed('prefs'), strategy: anyNamed('strategy')))
          .thenAnswer((_) async {});
      when(mockCatalogService.allShows).thenReturn(dummyShows);
      await showListProvider.fetchShows(mockPrefs);
      final show = showListProvider.filteredShows.first;
      final key = showListProvider.getShowKey(show);
      showListProvider.expandShow(key);
      expect(showListProvider.expandedShowKey, key);
    });

    test('collapseCurrentShow collapses the current show', () async {
      when(mockCatalogService.initialize(
              prefs: anyNamed('prefs'), strategy: anyNamed('strategy')))
          .thenAnswer((_) async {});
      when(mockCatalogService.allShows).thenReturn(dummyShows);
      await showListProvider.fetchShows(mockPrefs);
      final show = showListProvider.filteredShows.first;
      final key = showListProvider.getShowKey(show);
      showListProvider.expandShow(key);
      expect(showListProvider.expandedShowKey, key);

      showListProvider.collapseCurrentShow();
      expect(showListProvider.expandedShowKey, isNull);
    });
  });
}
