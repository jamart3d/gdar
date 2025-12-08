import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gdar/api/show_service.dart';
import 'package:gdar/models/show.dart';
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
  String? _expandedShowName;
  String? _loadingShowName;
  bool _isArchiveReachable = false;
  bool _hasCheckedArchive = false;
  bool _sortOldestFirst = true;

  // Public getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get expandedShowName => _expandedShowName;
  String? get loadingShowName => _loadingShowName;
  List<Show> get allShows => _allShows;
  bool get isArchiveReachable => _isArchiveReachable;
  bool get hasCheckedArchive => _hasCheckedArchive;

  int get totalShnids =>
      _allShows.fold(0, (sum, show) => sum + show.sources.length);

  void setArchiveStatus(bool isReachable) {
    _isArchiveReachable = isReachable;
    _hasCheckedArchive = true;
    notifyListeners();
  }

  // Cached filtered shows
  List<Show> _filteredShowsCache = [];
  List<Show> get filteredShows => _filteredShowsCache;

  void _updateFilteredShows() {
    const bool hideGdShowsInternally = true;
    _filteredShowsCache = _allShows
        .where((show) {
          // 1. Filter out internal GD shows if flag is set
          if (hideGdShowsInternally && show.hasFeaturedTrack) return false;

          // 2. Filter out Blocked Shows (Rating == -1)
          if (_showRatings[show.name] == -1) return false;

          final query = _searchQuery.toLowerCase();
          if (query.isEmpty) return true;
          return show.venue.toLowerCase().contains(query) ||
              show.formattedDate.toLowerCase().contains(query);
        })
        .map((show) {
          // 3. Filter out Blocked Sources (Rating == -1) within the show
          // We create a new Show instance with only the valid sources.
          // This allows the UI to react to blocked sources (e.g. collapse if only 1 remains).
          final validSources = show.sources.where((source) {
            return _showRatings[source.id] != -1;
          }).toList();

          return Show(
            name: show.name,
            artist: show.artist,
            date: show.date,
            venue: show.venue,
            sources: validSources,
            hasFeaturedTrack: show.hasFeaturedTrack,
          );
        })
        .where((show) => show.sources.isNotEmpty)
        .toList();
  }

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

  void update(SettingsProvider settings) {
    bool shouldNotify = false;

    if (_sortOldestFirst != settings.sortOldestFirst) {
      _sortOldestFirst = settings.sortOldestFirst;
      _sortShows();
      shouldNotify = true;
    }

    // Check if ratings have changed
    if (!mapEquals(_showRatings, settings.showRatings)) {
      _showRatings = Map.from(settings.showRatings);
      _updateFilteredShows(); // Update cache when ratings change

      // Check if the currently expanded show still exists and has multiple sources.
      // If not, collapse it.
      if (_expandedShowName != null) {
        final expandedShow = _filteredShowsCache.firstWhere(
            (s) => s.name == _expandedShowName,
            orElse: () =>
                Show(name: '', artist: '', date: '', venue: '', sources: []));
        if (expandedShow.sources.length <= 1) {
          _expandedShowName = null;
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

  // Methods
  Future<void> fetchShows() async {
    try {
      final shows = await _showService.getShows();
      _allShows = shows;
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
    if (_expandedShowName == show.name) {
      // Collapse the current show
      _expandedShowName = null;
    } else {
      // Expand the new show
      _expandedShowName = show.name;
    }
    notifyListeners();
  }

  void setLoadingShow(String? showName) {
    if (_loadingShowName != showName) {
      _loadingShowName = showName;
      notifyListeners();
    }
  }

  // Used to expand a show, e.g., when the current playing show is tapped.
  void expandShow(Show show) {
    _expandedShowName = show.name;
    notifyListeners();
  }

  void collapseCurrentShow() {
    _expandedShowName = null;
    notifyListeners();
  }
}
