import 'package:flutter/foundation.dart';
import 'package:gdar/api/show_service.dart';
import 'package:gdar/models/show.dart';

class ShowListProvider with ChangeNotifier {
  // Private state
  List<Show> _allShows = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _expandedShowName;
  String? _expandedShnid;
  String? _loadingShowName;

  // Public getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get expandedShowName => _expandedShowName;
  String? get expandedShnid => _expandedShnid;
  String? get loadingShowName => _loadingShowName;

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
  ShowListProvider() {
    fetchShows();
  }

  // Methods
  Future<void> fetchShows() async {
    try {
      final shows = await ShowService.instance.getShows();
      _allShows = shows;
    } catch (e) {
      _error = "Failed to load shows. Please restart the app.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void onShowTapped(Show show) {
    if (_expandedShowName == show.name) {
      // Collapse the current show
      _expandedShowName = null;
      _expandedShnid = null;
    } else {
      // Expand the new show
      _expandedShowName = show.name;
      _expandedShnid = null; // Always collapse sources when expanding a new show
    }
    notifyListeners();
  }

  void onShnidTapped(String shnid) {
    if (_expandedShnid == shnid) {
      // Collapse the source
      _expandedShnid = null;
    } else {
      // Expand the source
      _expandedShnid = shnid;
    }
    notifyListeners();
  }

  void setLoadingShow(String? showName) {
    if (_loadingShowName != showName) {
      _loadingShowName = showName;
      notifyListeners();
    }
  }

  // Used when returning from playback screen to re-expand the correct show/source
  void expandToShow(Show show, {String? specificShnid}) {
    _expandedShowName = show.name;
    _expandedShnid = specificShnid;
    notifyListeners();
  }

  // Directly sets the expanded show and source, e.g., on long-press play
  void expandShowAndSource(String showName, String sourceId) {
    _expandedShowName = showName;
    _expandedShnid = sourceId;
    notifyListeners();
  }

  void collapseCurrentShow() {
    _expandedShowName = null;
    _expandedShnid = null;
    notifyListeners();
  }
}
