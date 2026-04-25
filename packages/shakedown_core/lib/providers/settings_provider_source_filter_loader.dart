part of 'settings_provider.dart';

mixin _SettingsProviderSourceFilterLoaderExtension
    on ChangeNotifier, _SettingsProviderSourceFiltersFields {
  SharedPreferences get _prefs;

  void _loadSourceFilterPreferences() {
    _randomOnlyUnplayed =
        _prefs.getBool(_randomOnlyUnplayedKey) ??
        DefaultSettings.randomOnlyUnplayed;
    _randomOnlyHighRated =
        _prefs.getBool(_randomOnlyHighRatedKey) ??
        DefaultSettings.randomOnlyHighRated;
    _randomExcludePlayed =
        _prefs.getBool(_randomExcludePlayedKey) ??
        DefaultSettings.randomExcludePlayed;
    _filterHighestShnid = _prefs.getBool(_filterHighestShnidKey) ?? true;

    final categoriesJson = _prefs.getString(_sourceCategoryFiltersKey);
    if (categoriesJson != null) {
      try {
        final decoded = json.decode(categoriesJson) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          if (_sourceCategoryFilters.containsKey(key) && value is bool) {
            _sourceCategoryFilters[key] = value;
          }
        });
      } catch (_) {
        // Keep defaults when persisted data is malformed.
      }
    } else {
      _sourceCategoryFilters = Map.from(DefaultSettings.sourceCategoryFilters);
    }

    if (kIsWeb && !(_prefs.getBool(_webSourceFiltersInitKey) ?? false)) {
      _sourceCategoryFilters.updateAll((key, _) => key == 'matrix');
      _prefs.setBool(_webSourceFiltersInitKey, true);
      _prefs.setString(
        _sourceCategoryFiltersKey,
        json.encode(_sourceCategoryFilters),
      );
    }
  }
}
