import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown/utils/logger.dart';
import '../models/show.dart';
import '../models/rating.dart';

enum CatalogLoadingStrategy {
  inMemory, // Default (JSON loaded)
  lazy, // Not used in Hybrid mode currently, but kept for API compat if needed
}

/// Hybrid Service:
/// - Shows: Loaded from JSON (in-memory)
/// - Ratings: Stored in Hive (persistent)
class CatalogService {
  static CatalogService _instance = CatalogService._internal();
  factory CatalogService() => _instance;
  CatalogService._internal();

  @visibleForTesting
  static void setMock(CatalogService mock) {
    _instance = mock;
  }

  late Box<Rating> _ratingsBox;
  late Box<int> _playCountsBox;
  late Box<bool> _historyBox; // Stores played status (Source ID -> true)
  List<Show>? _showsCache;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes the service.
  /// 1. Opens Hive Box for Ratings.
  /// 2. Loads JSON catalog (background isolate).
  Future<void> initialize(
      {required SharedPreferences prefs,
      CatalogLoadingStrategy strategy =
          CatalogLoadingStrategy.inMemory}) async {
    if (_isInitialized) return;

    // 1. Init Hive
    await Hive.initFlutter();
    // Register Adapters if not already registered (check ID 0 for Rating)
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(RatingAdapter());

    // Open Boxes
    _ratingsBox = await Hive.openBox<Rating>('ratings');
    _playCountsBox = await Hive.openBox<int>('play_counts');
    _historyBox = await Hive.openBox<bool>('user_history');
    logger.i('Hive Boxes (Ratings, PlayCounts, History) opened.');

    // 1b. Migrate from SharedPreferences if needed
    await _migrateFromPreferences(prefs);

    // 2. Load Shows (JSON)
    if (_showsCache == null) {
      await _loadShowsFromJson();
    }

    _isInitialized = true;
  }

  // No-op for Hybrid, but kept for interface compatibility
  Future<void> switchStrategy(CatalogLoadingStrategy newStrategy) async {}

  Future<void> _loadShowsFromJson() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/output.optimized_src.json');

      // Use compute for JSON parsing to avoid blocking UI
      final List<Show> shows = await compute(parseShows, jsonString);

      _showsCache = shows;
      logger.i('Loaded ${_showsCache!.length} shows from JSON.');
    } catch (e) {
      logger.e('Error loading shows from JSON: $e');
      _showsCache = [];
    }
  }

  // Isolate entry point
  @visibleForTesting
  static List<Show> parseShows(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString);
    final List<Show> loadedShows =
        jsonList.map((j) => Show.fromJson(j)).toList();

    // Post-processing (Unify Venues, Merge Dates, Sort)
    // Mirrors logic from legacy ShowService
    final Map<String, Show> mergedShows = {};
    final Map<String, String> dateToVenue = {};

    for (final show in loadedShows) {
      if (dateToVenue.containsKey(show.date)) {
        show.venue = dateToVenue[show.date]!;
      } else {
        dateToVenue[show.date] = show.venue;
      }
    }

    for (final show in loadedShows) {
      if (mergedShows.containsKey(show.date)) {
        final existing = mergedShows[show.date]!;
        final existingIds = existing.sources.map((s) => s.id).toSet();
        for (final source in show.sources) {
          if (!existingIds.contains(source.id)) {
            existing.sources.add(source);
            existingIds.add(source.id);
          }
        }
      } else {
        // Create fresh object with copied list
        mergedShows[show.date] = Show(
            name: show.name,
            artist: show.artist,
            date: show.date,
            venue: show.venue, // Unified venue
            location: show.location,
            sources: List.from(show.sources),
            hasFeaturedTrack: show.hasFeaturedTrack);
      }
    }

    final finalShows = mergedShows.values.toList();

    // Sort
    finalShows.sort((a, b) => a.date.compareTo(b.date));

    // Final touch-ups
    for (final show in finalShows) {
      show.hasFeaturedTrack = show.sources.any((source) => source.tracks
          .any((track) => track.title.toLowerCase().startsWith('gd')));
      show.sources.sort((a, b) => a.id.compareTo(b.id));
    }

    return finalShows;
  }

  // Accessors
  List<Show> get allShows => _showsCache ?? [];

  // Rating Methods
  Future<void> addRating(String sourceId, int ratingValue) async {
    if (!_isInitialized) return; // Guard

    if (ratingValue == 0) {
      _ratingsBox.delete(sourceId); // Remove if 0 (Unplayed)
    } else {
      final rating = Rating(
        sourceId: sourceId,
        rating: ratingValue,
        timestamp: DateTime.now(),
      );
      await _ratingsBox.put(sourceId, rating);
    }
  }

  int getRating(String sourceId) {
    if (!_isInitialized) return 0;
    final r = _ratingsBox.get(sourceId);
    return r?.rating ?? 0; // Return 0 if not found
  }

  // Play Count Methods
  Future<void> incrementPlayCount(String sourceId) async {
    if (!_isInitialized) return;
    int current = _playCountsBox.get(sourceId) ?? 0;
    await _playCountsBox.put(sourceId, current + 1);
  }

  int getPlayCount(String sourceId) {
    if (!_isInitialized) return 0;
    return _playCountsBox.get(sourceId) ?? 0;
  }

  ValueListenable<Box<int>> get playCountsListenable {
    if (!_isInitialized) {
      throw Exception('CatalogService not initialized');
    }
    return _playCountsBox.listenable();
  }

  // History Methods
  bool isPlayed(String sourceId) {
    if (!_isInitialized) return false;
    return _historyBox.get(sourceId) ?? false;
  }

  Future<void> markAsPlayed(String sourceId) async {
    if (!_isInitialized) return;
    if (!_historyBox.containsKey(sourceId)) {
      await _historyBox.put(sourceId, true);
    }
  }

  Future<void> togglePlayed(String sourceId) async {
    if (!_isInitialized) return;
    if (_historyBox.containsKey(sourceId)) {
      await _historyBox.delete(sourceId);
    } else {
      await _historyBox.put(sourceId, true);
    }
  }

  // Set Rating (Alias for addRating to match existing pattern better)
  Future<void> setRating(String sourceId, int rating) async {
    await addRating(sourceId, rating);
  }

  ValueListenable<Box<bool>> get historyListenable {
    if (!_isInitialized) throw Exception('CatalogService not initialized');
    return _historyBox.listenable();
  }

  ValueListenable<Box<Rating>> get ratingsListenable {
    if (!_isInitialized) throw Exception('CatalogService not initialized');
    return _ratingsBox.listenable();
  }

  // Clean up
  Future<void> close() async {
    if (_isInitialized) {
      await _ratingsBox.close();
      await _playCountsBox.close();
      await _historyBox.close();
    }
  }

  // Migration Logic
  // Migration Logic
  Future<void> _migrateFromPreferences(SharedPreferences prefs) async {
    const String showRatingsKey = 'show_ratings';
    const String playedShowsKey = 'played_shows';

    bool migrationOccurred = false;

    // Migrate Ratings
    if (prefs.containsKey(showRatingsKey)) {
      logger.i('Migrating Ratings from SharedPreferences...');
      final String? ratingsJson = prefs.getString(showRatingsKey);
      if (ratingsJson != null) {
        try {
          final Map<String, dynamic> decoded = json.decode(ratingsJson);
          for (var entry in decoded.entries) {
            final sourceId = entry.key;
            final ratingVal = entry.value as int;
            // Only migrate if not already in Hive
            if (!_ratingsBox.containsKey(sourceId)) {
              await addRating(sourceId, ratingVal);
            }
          }
        } catch (e) {
          logger.e('Error migrating ratings: $e');
        }
      }
      await prefs.remove(showRatingsKey);
      migrationOccurred = true;
    }

    // Migrate History
    if (prefs.containsKey(playedShowsKey)) {
      logger.i('Migrating History from SharedPreferences...');
      final List<String>? playedList = prefs.getStringList(playedShowsKey);
      if (playedList != null) {
        for (var sourceId in playedList) {
          if (!_historyBox.containsKey(sourceId)) {
            await _historyBox.put(sourceId, true);
          }
        }
      }
      await prefs.remove(playedShowsKey);
      migrationOccurred = true;
    }

    if (migrationOccurred) {
      logger.i('Migration completed successfully.');
    }
  }

  @visibleForTesting
  Future<void> reset() async {
    await close();
    _isInitialized = false;
    _showsCache = null;
  }
}
