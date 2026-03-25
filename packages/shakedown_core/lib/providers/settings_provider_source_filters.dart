part of 'settings_provider.dart';

const String _randomOnlyUnplayedKey = 'random_only_unplayed';
const String _randomOnlyHighRatedKey = 'random_only_high_rated';
const String _randomExcludePlayedKey = 'random_exclude_played';
const String _filterHighestShnidKey = 'filter_highest_shnid';
const String _sourceCategoryFiltersKey = 'source_category_filters';
const String _webSourceFiltersInitKey = 'web_source_filters_init_v1';

mixin _SettingsProviderSourceFiltersFields {
  bool _randomOnlyUnplayed = false;
  bool _randomOnlyHighRated = false;
  bool _randomExcludePlayed = false;
  bool _filterHighestShnid = false;
  Map<String, bool> _sourceCategoryFilters = {
    'matrix': true,
    'ultra': false,
    'betty': false,
    'sbd': false,
    'fm': false,
    'dsbd': false,
    'unk': false,
  };
}

mixin _SettingsProviderSourceFiltersExtension
    on ChangeNotifier, _SettingsProviderSourceFiltersFields {
  SharedPreferences get _prefs;
  Future<void> _updatePreference(String key, bool value);

  bool get randomOnlyUnplayed => _randomOnlyUnplayed;
  bool get randomOnlyHighRated => _randomOnlyHighRated;
  bool get randomExcludePlayed => _randomExcludePlayed;
  bool get filterHighestShnid => _filterHighestShnid;
  Map<String, bool> get sourceCategoryFilters => _sourceCategoryFilters;

  void toggleRandomOnlyUnplayed() => _updatePreference(
    _randomOnlyUnplayedKey,
    _randomOnlyUnplayed = !_randomOnlyUnplayed,
  );

  void toggleRandomOnlyHighRated() => _updatePreference(
    _randomOnlyHighRatedKey,
    _randomOnlyHighRated = !_randomOnlyHighRated,
  );

  void toggleRandomExcludePlayed() => _updatePreference(
    _randomExcludePlayedKey,
    _randomExcludePlayed = !_randomExcludePlayed,
  );

  void toggleFilterHighestShnid() => _updatePreference(
    _filterHighestShnidKey,
    _filterHighestShnid = !_filterHighestShnid,
  );

  Future<void> setSourceCategoryFilter(String category, bool isActive) async {
    _sourceCategoryFilters[category] = isActive;
    if (!_sourceCategoryFilters.containsValue(true)) {
      _sourceCategoryFilters[category] = true;
    }
    notifyListeners();
    await _saveSourceCategoryFilters();
  }

  Future<void> setSoloSourceCategoryFilter(String category) async {
    _sourceCategoryFilters.forEach((key, _) {
      _sourceCategoryFilters[key] = key == category;
    });
    notifyListeners();
    await _saveSourceCategoryFilters();
  }

  Future<void> _saveSourceCategoryFilters() async {
    await _prefs.setString(
      _sourceCategoryFiltersKey,
      json.encode(_sourceCategoryFilters),
    );
  }

  Future<void> enableAllSourceCategories() async {
    for (final key in _sourceCategoryFilters.keys) {
      _sourceCategoryFilters[key] = true;
    }
    notifyListeners();
    await _saveSourceCategoryFilters();
  }
}
