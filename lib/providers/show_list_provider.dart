import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gdar/api/show_service.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/utils/logger.dart';
import 'package:http/http.dart' as http;

class ShowListProvider with ChangeNotifier {
  final ShowService _showService;

  // Private state
  List<Show> _allShows = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _expandedShowKey;
  String? _loadingShowKey;
  bool _isArchiveReachable = false;
  bool _hasCheckedArchive = false;
  bool _sortOldestFirst = true;

  // Public getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get expandedShowKey => _expandedShowKey;
  String? get loadingShowKey => _loadingShowKey;
  List<Show> get allShows => _allShows;
  bool get isArchiveReachable => _isArchiveReachable;
  bool get hasCheckedArchive => _hasCheckedArchive;

  int get totalShnids =>
      _allShows.fold(0, (sum, show) => sum + show.sources.length);

  String getShowKey(Show show) => '${show.name}_${show.date}';

  void setArchiveStatus(bool isReachable) {
    _isArchiveReachable = isReachable;
    _hasCheckedArchive = true;
    notifyListeners();
  }

  // Cached filtered shows
  List<Show> _filteredShowsCache = [];
  List<Show> get filteredShows => _filteredShowsCache;

  // _updateFilteredShows moved below to access new settings

  // Constructor
  ShowListProvider({ShowService? showService})
      : _showService = showService ?? ShowService();

  Future<void> init() async {
    await Future.wait([
      fetchShows(),
      checkArchiveStatus(),
    ]);
  }

  Map<String, int> _showRatings = {};
  bool _filterHighestShnid = false;
  bool _useStrictSrcCategorization = true; // Default
  Map<String, bool> _sourceCategoryFilters = {};

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

    // Check if ratings have changed
    if (!mapEquals(_showRatings, settings.showRatings)) {
      _showRatings = Map.from(settings.showRatings);
      filtersChanged = true;
    }

    if (filtersChanged) {
      _updateFilteredShows();

      // Collapse expanded show if it becomes invalid or has few sources loop
      if (_expandedShowKey != null) {
        final expandedShow = _filteredShowsCache.firstWhere(
            (s) => getShowKey(s) == _expandedShowKey,
            orElse: () =>
                Show(name: '', artist: '', date: '', venue: '', sources: []));

        // If hidden entirely
        if (expandedShow.name.isEmpty) {
          _expandedShowKey = null;
        } else if (expandedShow.sources.length <= 1 && !_filterHighestShnid) {
          // Original logic: collapse if single source.
          // But with filtering we might force it to single source.
          // If it's single source due to filtering, maybe we still show it?
          // The UI usually auto-expands single source shows in some flows,
          // but here the logic was likely "don't keep it expanded if it's simpler now"?
          // Actually, the original logic was: "if expandedShow.sources.length <= 1 ... _expandedShowName = null".
          // This implies standard behavior for single-source shows is collapsed/inline.
          _expandedShowKey = null;
        }
      }
      shouldNotify = true;
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  void _sortShows() {
    if (_sortOldestFirst) {
      _allShows.sort((a, b) => a.date.compareTo(b.date));
    } else {
      _allShows.sort((a, b) => b.date.compareTo(a.date));
    }
    _updateFilteredShows(); // Update cache when sort order changes
  }

  Set<String> _getCategoriesForSource(Source source) {
    final Set<String> categories = {};
    final url =
        source.tracks.isNotEmpty ? source.tracks.first.url.toLowerCase() : '';
    final srcType = source.src?.toLowerCase() ?? '';

    // Check for "Unknown" shows (featured tracks starting with 'gd')
    bool hasFeatTrack = source.tracks
        .any((track) => track.title.toLowerCase().startsWith('gd'));
    if (hasFeatTrack) {
      categories.add('unk');
    }

    // Strict Mode: Use only the 'src' attribute
    if (_useStrictSrcCategorization) {
      if (srcType == 'sbd') categories.add('sbd');
      if (srcType == 'mtx' || srcType == 'matrix') categories.add('matrix');
      if (srcType == 'ultra') categories.add('ultra');

      // Extended strict mode to support additional types present in optimized_src.json
      if (srcType == 'betty') categories.add('betty');
      if (srcType == 'dsbd') categories.add('dsbd');
      if (srcType == 'fm') categories.add('fm');

      return categories;
    }

    if (srcType == 'ultra' ||
        url.contains('ultra') ||
        url.contains('healy') ||
        url.contains('sbd-matrix')) {
      categories.add('ultra');
    }

    if (url.contains('betty') || url.contains('bbd')) categories.add('betty');

    // Matrix (Strict: Exclude Ultra variations)
    if (srcType == 'mtx' ||
        srcType == 'matrix' ||
        url.contains('mtx') ||
        url.contains('matrix')) {
      bool isExcluded = url.contains('sbd-matrix') ||
          url.contains('ultramatrix') ||
          url.contains('ultra.mtx') ||
          url.contains('ultra.matrix');

      if (!isExcluded) {
        categories.add('matrix');
      }
    }
    if (url.contains('dsbd')) categories.add('dsbd');
    if (url.contains('fm') || url.contains('prefm') || url.contains('pre-fm')) {
      categories.add('fm');
    }
    if (srcType == 'sbd' || url.contains('sbd')) categories.add('sbd');

    return categories;
  }

  bool _isSourceAllowed(Source source) {
    if (_sourceCategoryFilters.isEmpty) return true;

    final categories = _getCategoriesForSource(source);

    // If no categories detected, we allow it (fail open for AUD etc)
    if (categories.isEmpty) return true;

    // Standard "OR" filtering. Match ANY enabled category.
    for (var cat in categories) {
      if (_sourceCategoryFilters[cat] == true) return true;
    }

    return false;
  }

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
            // Force include if playing
            if (_playingSourceId != null && source.id == _playingSourceId) {
              return true;
            }

            // Blocked
            if (_showRatings[source.id] == -1) return false;
            // Category
            return _isSourceAllowed(source);
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

  // Methods
  Future<void> fetchShows() async {
    try {
      final shows = await _showService.getShows();
      _allShows = shows;
      _scanAvailableCategories(); // Polulate categories
      _sortShows();
      // _sortShows calls _updateFilteredShows, so no need to call it again
    } catch (e) {
      _error = "Failed to load shows. Please restart the app.";
      notifyListeners();
    } finally {
      _isLoading = false;
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

  void onShowTap(Show show) {
    final key = getShowKey(show);
    if (_expandedShowKey == key) {
      // Collapse the current show
      _expandedShowKey = null;
    } else {
      // Expand the new show
      _expandedShowKey = key;
    }
    notifyListeners();
  }

  void setLoadingShow(Show? show) {
    final key = show != null ? getShowKey(show) : null;
    if (_loadingShowKey != key) {
      _loadingShowKey = key;
      notifyListeners();
    }
  }

  // Used to expand a show, e.g., when the current playing show is tapped.
  void expandShow(Show show) {
    _expandedShowKey = getShowKey(show);
    notifyListeners();
  }

  void collapseCurrentShow() {
    _expandedShowKey = null;
    notifyListeners();
  }
}
