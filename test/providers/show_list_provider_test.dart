import 'package:flutter_test/flutter_test.dart';
import 'package:gdar/api/show_service.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/providers/show_list_provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'show_list_provider_test.mocks.dart';

@GenerateMocks([ShowService])
void main() {
  late ShowListProvider showListProvider;
  late MockShowService mockShowService;

  // Helper function to create a dummy show
  Show createDummyShow(String name, String date,
      {bool hasFeaturedTrack = false}) {
    return Show(
      name: name,
      artist: 'Grateful Dead',
      date: date,
      year: date.split('-').first,
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
    mockShowService = MockShowService();
    showListProvider = ShowListProvider(showService: mockShowService);
  });

  group('ShowListProvider Tests', () {
    test('Initial values are correct', () {
      expect(showListProvider.isLoading, isTrue);
      expect(showListProvider.error, isNull);
      expect(showListProvider.searchQuery, isEmpty);
      expect(showListProvider.filteredShows, isEmpty);
    });

    test('fetchShows successfully loads shows', () async {
      when(mockShowService.getShows()).thenAnswer((_) async => dummyShows);

      await showListProvider.fetchShows();

      expect(showListProvider.isLoading, isFalse);
      expect(showListProvider.error, isNull);
      // The filteredShows getter removes the featured track show
      expect(showListProvider.filteredShows.length, 2);
    });

    test('fetchShows handles errors', () async {
      when(mockShowService.getShows()).thenThrow(Exception('Failed to load'));

      await showListProvider.fetchShows();

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
      when(mockShowService.getShows()).thenAnswer((_) async => dummyShows);
      await showListProvider.fetchShows();

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
      when(mockShowService.getShows()).thenAnswer((_) async => dummyShows);
      await showListProvider.fetchShows();

      expect(showListProvider.filteredShows.length, 2);
    });

    test('onShowTap expands and collapses a show', () async {
      when(mockShowService.getShows()).thenAnswer((_) async => dummyShows);
      await showListProvider.fetchShows();
      final show = showListProvider.filteredShows.first;

      showListProvider.onShowTap(show);
      expect(showListProvider.expandedShowName, show.name);

      showListProvider.onShowTap(show);
      expect(showListProvider.expandedShowName, isNull);
    });

    test('setLoadingShow updates the loading show name', () {
      const showName = 'show1';
      showListProvider.setLoadingShow(showName);
      expect(showListProvider.loadingShowName, showName);
    });

    test('expandShow expands the given show', () async {
      when(mockShowService.getShows()).thenAnswer((_) async => dummyShows);
      await showListProvider.fetchShows();
      final show = showListProvider.filteredShows.first;
      showListProvider.expandShow(show);
      expect(showListProvider.expandedShowName, show.name);
    });

    test('collapseCurrentShow collapses the current show', () async {
      when(mockShowService.getShows()).thenAnswer((_) async => dummyShows);
      await showListProvider.fetchShows();
      final show = showListProvider.filteredShows.first;
      showListProvider.expandShow(show);
      expect(showListProvider.expandedShowName, show.name);

      showListProvider.collapseCurrentShow();
      expect(showListProvider.expandedShowName, isNull);
    });
  });
}
