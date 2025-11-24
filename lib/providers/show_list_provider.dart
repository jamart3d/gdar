import 'package:flutter/foundation.dart';
import 'package:gdar/api/show_service.dart';
import 'package:gdar/models/show.dart';

class ShowListProvider with ChangeNotifier {
  final ShowService _showService;

  // Private state
  List<Show> _allShows = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String? _expandedShowName;
  String? _loadingShowName;

  // Public getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get expandedShowName => _expandedShowName;
  String? get loadingShowName => _loadingShowName;
  List<Show> get allShows => _allShows;

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
    await fetchShows();
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
