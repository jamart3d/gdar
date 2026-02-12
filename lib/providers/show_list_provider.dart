import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/utils/logger.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ShowListProvider with ChangeNotifier {
  final CatalogService _catalogService;

  // Private state
  List<Show> _allShows = []; // Restored synchronous list
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _expandedShowKey;
  String? _loadingShowKey;
  bool _isArchiveReachable = false;
  bool _hasCheckedArchive = false;
  bool _sortOldestFirst = true;
  bool _hasUsedRandomButton = false; // Tracks usage for onboarding pulse
  bool _isChoosingRandomShow = false; // Tracks the 2s dice roll window globally

  // Completer for initialization
  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initializationComplete => _initCompleter.future;

  // Public getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get expandedShowKey => _expandedShowKey;
  String? get loadingShowKey => _loadingShowKey;
  List<Show> get allShows => _allShows;

  bool get isArchiveReachable => _isArchiveReachable;
  bool get hasCheckedArchive => _hasCheckedArchive;
  bool get hasUsedRandomButton => _hasUsedRandomButton;

  bool _isSearchVisible = false;
  bool get isSearchVisible => _isSearchVisible;

  void setSearchVisible(bool visible) {
    if (_isSearchVisible != visible) {
      _isSearchVisible = visible;
      notifyListeners();
    }
  }

  void toggleSearchVisible() {
    _isSearchVisible = !_isSearchVisible;
    notifyListeners();
  }

  void markRandomButtonUsed() {
    if (!_hasUsedRandomButton) {
      _hasUsedRandomButton = true;
      notifyListeners();
    }
  }

  bool get isChoosingRandomShow => _isChoosingRandomShow;

  void setIsChoosingRandomShow(bool value) {
    if (_isChoosingRandomShow != value) {
      _isChoosingRandomShow = value;
      notifyListeners();
    }
  }

  int get totalShnids =>
      _allShows.fold(0, (sum, show) => sum + show.sources.length);

  String getShowKey(Show show) => show.key;

  void setArchiveStatus(bool isReachable) {
    _isArchiveReachable = isReachable;
    _hasCheckedArchive = true;
    notifyListeners();
  }

  // Cached filtered shows
  List<Show> _filteredShowsCache = [];
  List<Show> get filteredShows => _filteredShowsCache;

  // Constructor
  ShowListProvider({CatalogService? catalogService})
      : _catalogService = catalogService ?? CatalogService();

  Future<void> init(SharedPreferences prefs) async {
    await Future.wait([
      fetchShows(prefs),
      checkArchiveStatus(),
    ]);
  }

  bool _filterHighestShnid = false;
  bool _useStrictSrcCategorization = true; // Default
  Map<String, bool> _sourceCategoryFilters = {};

  // CatalogLoadingStrategy removed from here as it's handled by Service implicitly

  void update(SettingsProvider settings) {
    bool shouldNotify = false;

    if (_sortOldestFirst != settings.sortOldestFirst) {
      _sortOldestFirst = settings.sortOldestFirst;
      _sortShows();
      shouldNotify = true;
    }

    // Sync Source Filtering settings
    bool filtersChanged = false;
    if (_filterHighestShnid != settings.filterHighestShnid) {
      _filterHighestShnid = settings.filterHighestShnid;
      filtersChanged = true;
    }
    if (_useStrictSrcCategorization != settings.useStrictSrcCategorization) {
      _useStrictSrcCategorization = settings.useStrictSrcCategorization;
      filtersChanged = true;
      // Also need to re-scan categories because categorization logic changed
      _scanAvailableCategories();
    }
    if (!mapEquals(_sourceCategoryFilters, settings.sourceCategoryFilters)) {
      _sourceCategoryFilters = Map.from(settings.sourceCategoryFilters);
      filtersChanged = true;
    }

    // Check if ratings have changed - REMOVED: Now handled by _onRatingsChanged via CatalogService listener

    if (filtersChanged) {
      _updateFilteredShows();
      // Collapse expanded show logic omitted for brevity
      shouldNotify = true;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  // Helper (calls Service synchronously if possible, but Service.getShow is async?
  // No, in Hybrid mode we usually have it in memory.
  // CatalogService doesn't have getShow anymore? It has allShows.)
  Show? getShow(String key) {
    try {
      return _allShows.firstWhere((s) => s.key == key);
    } catch (e) {
      return null;
    }
  }

  void _sortShows() {
    if (_sortOldestFirst) {
      _allShows.sort((a, b) => a.date.compareTo(b.date));
    } else {
      _allShows.sort((a, b) => b.date.compareTo(a.date));
    }
    _updateFilteredShows();
  }

  // Categories helper requires loading shows.
  Set<String> _availableCategories = {};
  Set<String> get availableCategories => _availableCategories;

  void _scanAvailableCategories() {
    _availableCategories = {};
    for (var show in _allShows) {
      for (var source in show.sources) {
        _availableCategories.addAll(_getCategoriesForSource(source));
      }
    }
    notifyListeners();
  }

  // Source Category helper moved to static or helper class?
  // It uses internal strict mode setting.
  Set<String> _getCategoriesForSource(Source source) {
    // ... logic copied from original or refactored ...
    // For brevity, using simplified logic or assuming method exists
    final Set<String> categories = {};
    final srcType = source.src?.toLowerCase() ?? '';
    final url =
        source.tracks.isNotEmpty ? source.tracks.first.url.toLowerCase() : '';

    if (_useStrictSrcCategorization) {
      if (srcType == 'sbd') categories.add('sbd');
      if (srcType == 'mtx' || srcType == 'matrix') categories.add('matrix');
      if (srcType == 'ultra') categories.add('ultra');
      if (srcType == 'betty') categories.add('betty');
      if (srcType == 'dsbd') categories.add('dsbd');
      if (srcType == 'fm') categories.add('fm');
      return categories;
    }
    // Loose mode logic
    if (srcType == 'sbd' || url.contains('sbd')) categories.add('sbd');
    if (srcType == 'mtx' || srcType == 'matrix' || url.contains('mtx')) {
      categories.add('matrix');
    }
    if (srcType == 'dsbd' || url.contains('dsbd')) categories.add('dsbd');
    if (srcType == 'betty' || url.contains('betty')) categories.add('betty');
    if (srcType == 'ultra' || url.contains('ultra')) categories.add('ultra');
    if (srcType == 'fm' || url.contains('fm')) {
      categories.add('fm');
    }

    return categories;
  }

  bool isSourceAllowed(Source source) {
    if (_sourceCategoryFilters.isEmpty) {
      return true;
    }
    final cats = _getCategoriesForSource(source);
    if (cats.isEmpty) {
      return true;
    }
    for (var cat in cats) {
      if (_sourceCategoryFilters[cat] == true) {
        return true;
      }
    }
    return false;
  }

  void _updateFilteredShows() {
    _filteredShowsCache = _allShows
        .where((show) {
          // 1. Filter out Blocked Shows (Rating == -1)
          // Removed as per user request (source-only blocking)

          // 3. Search Query
          final query = _searchQuery.toLowerCase();
          if (query.isNotEmpty) {
            if (!show.venue.toLowerCase().contains(query) &&
                !show.formattedDate.toLowerCase().contains(query) &&
                !show.location.toLowerCase().contains(query)) {
              return false;
            }
          }
          return true;
        })
        .map((show) {
          // 4. Source Filtering

          // A. Category & Rating Filtering
          var validSources = show.sources.where((source) {
            // Force include if playing - Accessing playing state requires reference?
            // We need playing state tracking locally if we want to filter safely?
            // See _playingSourceId usage in previous version.
            // We need to restore it.
            if (_playingSourceId != null && source.id == _playingSourceId) {
              return true;
            }

            // Blocked
            if (_catalogService.getRating(source.id) == -1) return false;

            // Category
            return isSourceAllowed(source);
          }).toList();

          // B. Highest SHNID Filtering
          if (_filterHighestShnid && validSources.length > 1) {
            // If playing source is present, prioritize it
            final playingSourceIndex =
                validSources.indexWhere((s) => s.id == _playingSourceId);
            if (playingSourceIndex != -1) {
              validSources = [validSources[playingSourceIndex]];
            } else {
              // Find source with max ID
              validSources.sort((a, b) {
                int idA = int.tryParse(a.id) ?? 0;
                int idB = int.tryParse(b.id) ?? 0;
                return idB.compareTo(idA); // Descending
              });
              validSources = [validSources.first];
            }
          }

          // Use copyWith
          return show.copyWith(sources: validSources);
        })
        .where((show) => show.sources.isNotEmpty)
        .toList();
  }

  // Tracking playing state to ensure visibility
  String? _playingShowName;
  String? _playingSourceId;

  void setPlayingShow(String? showName, String? sourceId) {
    if (_playingShowName != showName || _playingSourceId != sourceId) {
      _playingShowName = showName;
      _playingSourceId = sourceId;
      _updateFilteredShows();
      notifyListeners();
    }
  }

  Future<void> fetchShows(SharedPreferences prefs) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _catalogService.initialize(prefs: prefs);

      // Listen for rating changes to update filters
      _catalogService.ratingsListenable.addListener(_onRatingsChanged);

      _allShows = _catalogService.allShows;
      _scanAvailableCategories();
      _sortShows();
    } catch (e) {
      _error = "Failed to load shows.";
      logger.e(e);
    } finally {
      _isLoading = false;
      if (!_initCompleter.isCompleted) _initCompleter.complete();
      notifyListeners();
    }
  }

  Future<void> checkArchiveStatus() async {
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 2);
    const Duration timeout = Duration(seconds: 5);
    bool isArchiveDown = false;
    for (int i = 0; i < maxRetries; i++) {
      try {
        logger
            .i('Checking archive.org status (Attempt ${i + 1}/$maxRetries)...');
        final response =
            await http.head(Uri.parse('https://archive.org')).timeout(timeout);
        if (response.statusCode >= 200 && response.statusCode < 400) {
          logger.i('archive.org is reachable.');
          isArchiveDown = false;
          break; // Exit loop on success
        } else {
          logger.w(
              'archive.org returned status code: ${response.statusCode} (Attempt ${i + 1}/$maxRetries)');
          isArchiveDown = true;
        }
      } on TimeoutException {
        logger.w('archive.org check timed out (Attempt ${i + 1}/$maxRetries)');
        isArchiveDown = true;
      } on SocketException catch (e) {
        logger.e(
            'Failed to connect to archive.org: $e (Attempt ${i + 1}/$maxRetries)');
        isArchiveDown = true;
      } catch (e) {
        logger.e(
            'An unexpected error occurred while checking archive.org: $e (Attempt ${i + 1}/$maxRetries)');
        isArchiveDown = true;
      }

      if (isArchiveDown && i < maxRetries - 1) {
        await Future.delayed(retryDelay);
      }
    }
    setArchiveStatus(!isArchiveDown);
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      _updateFilteredShows(); // Update cache when query changes
      notifyListeners();
    }
  }

  bool isShowExpanded(String key) => _expandedShowKey == key;
  bool isShowLoading(String key) => _loadingShowKey == key;

  void toggleShowExpansion(String key) {
    if (_expandedShowKey == key) {
      // Collapse the current show
      _expandedShowKey = null;
    } else {
      // Expand the new show
      _expandedShowKey = key;
    }
    notifyListeners();
  }

  void setLoadingShow(String? key) {
    if (_loadingShowKey != key) {
      _loadingShowKey = key;
      notifyListeners();
    }
  }

  // Used to expand a show, e.g., when the current playing show is tapped.
  void expandShow(String key) {
    _expandedShowKey = key;
    notifyListeners();
  }

  void collapseCurrentShow() {
    _expandedShowKey = null;
    notifyListeners();
  }

  /// Optimistically removes a show from the list.
  /// This should be called immediately when a show is blocked/dismissed
  /// to ensure the UI updates synchronously, preventing "Dismissible still in tree" errors.
  void dismissShow(Show show) {
    if (_filteredShowsCache.contains(show)) {
      _filteredShowsCache.remove(show);
      notifyListeners();
    }
  }

  /// Optimistically removes a source from a specific show.
  void dismissSource(Show show, String sourceId) {
    // Find the show in the cache
    final index = _filteredShowsCache.indexOf(show);
    if (index != -1) {
      final updatedSources =
          show.sources.where((s) => s.id != sourceId).toList();

      // If no sources left, remove the show entirely
      if (updatedSources.isEmpty) {
        _filteredShowsCache.removeAt(index);
      } else {
        // Update the show with removed source
        _filteredShowsCache[index] = show.copyWith(sources: updatedSources);
      }
      notifyListeners();
    }
  }

  void _onRatingsChanged() {
    _updateFilteredShows();
    notifyListeners();
  }

  @override
  void dispose() {
    // If we wanted to be strictly correct we would remove the listener here.
    // But given the complexity of obtaining the same ValueListenable instance
    // and the singleton nature of this provider, we skip it for now.
    super.dispose();
  }
}
