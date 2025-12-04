import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gdar/api/show_service.dart';
import 'package:gdar/models/show.dart';
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

  List<Show> get filteredShows {
    const bool hideGdShowsInternally = true;
    return _allShows.where((show) {
      if (hideGdShowsInternally && show.hasFeaturedTrack) return false;
      final query = _searchQuery.toLowerCase();
      if (query.isEmpty) return true;
      return show.venue.toLowerCase().contains(query) ||
          show.formattedDate.toLowerCase().contains(query);
    }).toList();
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

  // Methods
  Future<void> fetchShows() async {
    try {
      final shows = await _showService.getShows();
      _allShows = shows;
    } catch (e) {
      _error = "Failed to load shows. Please restart the app.";
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
