import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gdar/utils/logger.dart';
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
  static final CatalogService _instance = CatalogService._internal();
  factory CatalogService() => _instance;
  CatalogService._internal();

  late Box<Rating> _ratingsBox;
  List<Show>? _showsCache;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Initializes the service.
  /// 1. Opens Hive Box for Ratings.
  /// 2. Loads JSON catalog (background isolate).
  Future<void> initialize(
      {CatalogLoadingStrategy strategy =
          CatalogLoadingStrategy.inMemory}) async {
    if (_isInitialized) return;

    // 1. Init Hive
    await Hive.initFlutter();
    // Register Adapters if not already registered (check ID 0 for Rating)
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(RatingAdapter());

    // Open Ratings Box
    _ratingsBox = await Hive.openBox<Rating>('ratings');
    logger.i('Hive Ratings Box opened.');

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

  // Clean up
  Future<void> close() async {
    if (_isInitialized) await _ratingsBox.close();
  }
}
