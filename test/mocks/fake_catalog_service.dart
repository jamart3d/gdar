import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shakedown/models/rating.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fake CatalogService to bypass Hive operations in widget tests
class FakeCatalogService extends CatalogService {
  final Map<String, bool> _history = {};
  final Map<String, Rating> _ratings = {};
  final Map<String, int> _playCounts = {};

  // Mock Boxes
  final ValueNotifier<Box<bool>> _historyNotifier =
      ValueNotifier(BoxMock<bool>({}));
  final ValueNotifier<Box<Rating>> _ratingsNotifier =
      ValueNotifier(BoxMock<Rating>({}));
  final ValueNotifier<Box<int>> _playCountsNotifier =
      ValueNotifier(BoxMock<int>({}));

  FakeCatalogService()
      : super.internal(); // Call internal constructor if accessible or use stub

  @override
  Future<void> initialize(
      {required SharedPreferences prefs,
      CatalogLoadingStrategy strategy =
          CatalogLoadingStrategy.inMemory}) async {
    // No-op or just set initialized flag if needed, but we intercept accessors
  }

  // We need to override the getters that checking `_isInitialized` or use private boxes
  // Since we can't easily override private fields, we rely on overriding the public methods that use them.

  @override
  Future<void> markAsPlayed(String sourceId) async {
    _history[sourceId] = true;
    _historyNotifier.value = BoxMock<bool>(_history);
    // Notify listeners if needed
    // _historyNotifier.notifyListeners();
  }

  @override
  bool isPlayed(String sourceId) => _history.containsKey(sourceId);

  @override
  ValueListenable<Box<bool>> get historyListenable => _historyNotifier;

  @override
  ValueListenable<Box<Rating>> get ratingsListenable => _ratingsNotifier;

  @override
  ValueListenable<Box<int>> get playCountsListenable => _playCountsNotifier;

  @override
  int getRating(String sourceId) => _ratings[sourceId]?.rating ?? 0;

  @override
  Future<void> addRating(String sourceId, int ratingValue) async {
    final rating = Rating(
      sourceId: sourceId,
      rating: ratingValue,
      timestamp: DateTime.now(),
    );
    _ratings[sourceId] = rating;
    _ratingsNotifier.value = BoxMock<Rating>(_ratings);
  }

  @override
  Future<void> setRating(String sourceId, int rating) async {
    await addRating(sourceId, rating);
  }

  @override
  Future<void> togglePlayed(String sourceId) async {
    if (_history.containsKey(sourceId)) {
      _history.remove(sourceId);
    } else {
      _history[sourceId] = true;
    }
    _historyNotifier.value = BoxMock<bool>(_history);
  }

  @override
  Future<void> reset() async {
    _history.clear();
    _ratings.clear();
    _playCounts.clear();
    _historyNotifier.value = BoxMock<bool>({});
    _ratingsNotifier.value = BoxMock<Rating>({});
    _playCountsNotifier.value = BoxMock<int>({});
  }
}

// Mock Box for ValueListenable
class BoxMock<T> extends Box<T> {
  final Map<dynamic, T> _data;
  BoxMock(this._data);

  @override
  T? get(key, {defaultValue}) => _data[key] ?? defaultValue;

  @override
  bool get isOpen => true;

  @override
  Iterable<T> get values => _data.values;

  @override
  bool containsKey(key) => _data.containsKey(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
