part of 'settings_provider.dart';

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
