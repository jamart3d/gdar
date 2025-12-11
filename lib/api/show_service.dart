import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/utils/logger.dart';

import '../models/source.dart';

class ShowService {
  List<Show>? _shows;

  Future<List<Show>> getShows() async {
    // If shows are already loaded, return the cached list immediately.
    if (_shows != null) {
      return _shows!;
    }

    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/output.optimized.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      final List<Show> loadedShows =
          jsonList.map((jsonItem) => Show.fromJson(jsonItem)).toList();

      // ** Post-processing Step 1: Unify venues for shows on the same date. **
      final Map<String, String> dateToFirstVenue = {};
      for (final show in loadedShows) {
        if (dateToFirstVenue.containsKey(show.date)) {
          show.venue = dateToFirstVenue[show.date]!;
        } else {
          dateToFirstVenue[show.date] = show.venue;
        }
      }

      // ** Post-processing Step 2: Merge shows with the same date **
      // This groups multiple JSON entries for the same date into a single Show object,
      // aggregating all their sources.
      final Map<String, Show> showsByDate = {};
      for (final show in loadedShows) {
        if (showsByDate.containsKey(show.date)) {
          // Date exists, so add this show's sources to the existing entry.
          showsByDate[show.date]!.sources.addAll(show.sources);
        } else {
          // First time seeing this date, create a new Show object in the map.
          // We create a copy to avoid issues with object references.
          showsByDate[show.date] = Show(
            name: show.name,
            artist: show.artist,
            date: show.date,
            venue: show.venue,
            sources:
                List<Source>.from(show.sources), // Create a copy of the list
            hasFeaturedTrack: show.hasFeaturedTrack,
          );
        }
      }
      final List<Show> finalShowList = showsByDate.values.toList();

      // Sort by date (oldest first)
      finalShowList.sort((a, b) => a.date.compareTo(b.date));

      // ** Post-processing Step 3: Final cleanup on the merged list **
      for (final show in finalShowList) {
        // a) Re-evaluate and set hasFeaturedTrack on the final merged show.
        show.hasFeaturedTrack = show.sources.any((source) => source.tracks
            .any((track) => track.title.toLowerCase().startsWith('gd')));

        // b) Sort sources by ID to ensure a consistent and predictable order in the UI.
        show.sources.sort((a, b) => a.id.compareTo(b.id));
      }

      // Cache the processed list of shows.
      _shows = finalShowList;

      logger.i(
          'Successfully loaded and processed ${_shows!.length} shows from ${loadedShows.length} entries.');

      return _shows!;
    } catch (e, stackTrace) {
      logger.e('Error loading shows', error: e, stackTrace: stackTrace);
      return []; // Return an empty list on failure.
    }
  }
}
