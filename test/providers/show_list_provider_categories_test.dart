import 'package:flutter_test/flutter_test.dart';
import 'package:gdar/providers/show_list_provider.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/models/track.dart';
import 'package:mockito/mockito.dart';
import 'show_list_provider_test.mocks.dart';

void main() {
  group('ShowListProvider Category Detection', () {
    late ShowListProvider provider;
    late MockCatalogService mockCatalogService;
    late MockSettingsProvider mockSettingsProvider;

    setUp(() {
      mockCatalogService = MockCatalogService();
      mockSettingsProvider = MockSettingsProvider();
      provider = ShowListProvider(catalogService: mockCatalogService);

      // Disable strict mode to test URL parsing
      when(mockSettingsProvider.useStrictSrcCategorization).thenReturn(false);
      when(mockSettingsProvider.sortOldestFirst).thenReturn(true);
      when(mockSettingsProvider.filterHighestShnid).thenReturn(false);
      when(mockSettingsProvider.sourceCategoryFilters).thenReturn({});
      when(mockSettingsProvider.showRatings).thenReturn({});

      provider.update(mockSettingsProvider);
    });

    test('should detect categories from sources', () async {
      // Create mock shows with specific source types
      final shows = [
        Show(
          name: 'show1',
          artist: 'Grateful Dead',
          date: '1977-05-08',
          venue: 'Cornell',
          sources: [
            Source(id: '1', src: 'sbd', tracks: [
              Track(
                  title: 't1',
                  url: 'http://foo/sbd/bar.mp3',
                  duration: 100,
                  trackNumber: 1,
                  setName: 'Set 1')
            ]),
            Source(id: '2', src: 'mtx', tracks: [
              Track(
                  title: 't2',
                  url: 'http://foo/mtx/bar.mp3',
                  duration: 100,
                  trackNumber: 1,
                  setName: 'Set 1')
            ]),
          ],
        ),
        Show(
          name: 'show2',
          artist: 'Grateful Dead',
          date: '1977-05-09',
          venue: 'Buffalo',
          sources: [
            Source(id: '3', src: 'aud', tracks: [
              Track(
                  title: 't3',
                  url: 'http://foo/betty/bar.mp3',
                  duration: 100,
                  trackNumber: 1,
                  setName: 'Set 1')
            ]), // Betty in URL
          ],
        ),
      ];

      when(mockCatalogService.initialize()).thenAnswer((_) async {});
      when(mockCatalogService.allShows).thenReturn(shows);

      await provider.fetchShows();

      expect(provider.availableCategories, contains('sbd'));
      expect(provider.availableCategories, contains('matrix'));
      expect(provider.availableCategories, contains('betty'));
      expect(provider.availableCategories,
          isNot(contains('ultra'))); // Should not contain ultra
    });
  });
}
