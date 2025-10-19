import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/utils/logger.dart';

class ShowService {
  ShowService._privateConstructor();
  static final ShowService instance = ShowService._privateConstructor();

  List<Show>? _shows;

  Future<List<Show>> getShows() async {
    // If shows are already loaded, return the cached list immediately.
    if (_shows != null) {
      return _shows!;
    }

    try {
      final String jsonString =
      await rootBundle.loadString('assets/data/shows1.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      final List<Show> loadedShows =
      jsonList.map((jsonItem) => Show.fromJson(jsonItem)).toList();

      // ** Logic to find and flag featured shows **
      // This now runs only once, before the data is cached.
      for (final show in loadedShows) {
        final bool isFeatured = show.sources.any((source) => source.tracks
            .any((track) => track.title.toLowerCase().startsWith('gd')));

        if (isFeatured) {
          show.hasFeaturedTrack = true;
        }
      }

      // Cache the processed list of shows.
      _shows = loadedShows;

      logger.i('Successfully loaded and parsed ${_shows!.length} shows.');

      return _shows!;
    } catch (e, stackTrace) {
      logger.e('Error loading shows', error: e, stackTrace: stackTrace);
      return []; // Return an empty list on failure.
    }
  }
}

