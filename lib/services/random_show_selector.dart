import 'dart:math';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/utils/logger.dart';

/// Service responsible for selecting a random (or next) show based on user settings.
class RandomShowSelector {
  static final Random _random = Random();

  /// Picks a show and source based on the provided candidates and settings.
  ///
  /// [candidates] - The list of shows to choose from (usually filtered or all shows).
  /// [settings] - The current settings provider state.
  /// [catalog] - The catalog service for checking ratings and play status.
  /// [currentShow] - The currently playing show (needed for "Play Next" logic).
  /// [showListProvider] - Optional reference for extra filtering checks (e.g., allowed sources).
  static ({Show show, Source source})? pick({
    required List<Show> candidates,
    required SettingsProvider settings,
    required CatalogService catalog,
    Show? currentShow,
    bool Function(Source)? isSourceAllowed,
  }) {
    if (candidates.isEmpty) {
      return (error: 'No shows available for playback.', result: null).result;
    }

    if (settings.nonRandom) {
      return _pickNextShow(
        candidates: candidates,
        currentShow: currentShow,
        catalog: catalog,
        isSourceAllowed: isSourceAllowed,
      );
    }

    return _pickWeightedRandom(
      candidates: candidates,
      settings: settings,
      catalog: catalog,
      isSourceAllowed: isSourceAllowed,
    );
  }

  static ({Show show, Source source})? _pickNextShow({
    required List<Show> candidates,
    required Show? currentShow,
    required CatalogService catalog,
    required bool Function(Source)? isSourceAllowed,
  }) {
    int currentIndex = -1;

    if (currentShow != null) {
      // We use indexWhere because object identity might differ if show objects are recreated
      currentIndex = candidates.indexWhere(
          (s) => s.date == currentShow.date && s.venue == currentShow.venue);
    }

    int nextIndex = (currentIndex + 1) % candidates.length;

    // Infinite loop protection in case ALL shows are blocked
    int attempts = 0;
    while (attempts < candidates.length) {
      final candidate = candidates[nextIndex];

      final validSources = candidate.sources.where((s) {
        if (catalog.getRating(s.id) == -1) return false; // Blocked
        if (isSourceAllowed != null && !isSourceAllowed(s)) {
          return false; // Filtered
        }
        return true;
      }).toList();

      if (validSources.isNotEmpty) {
        logger.i(
            'Sequential Playback: Selected next show ${candidate.date} (Index $nextIndex)');
        return (show: candidate, source: validSources.first);
      }

      nextIndex = (nextIndex + 1) % candidates.length;
      attempts++;
    }

    logger.w('Sequential Playback: All shows blocked or filtered.');
    return null;
  }

  static ({Show show, Source source})? _pickWeightedRandom({
    required List<Show> candidates,
    required SettingsProvider settings,
    required CatalogService catalog,
    required bool Function(Source)? isSourceAllowed,
  }) {
    final List<Show> playCandidates = [];
    final Map<Show, int> weights = {};
    final Map<Show, Source> selectedSourceMap = {};

    // For better feedback logging
    int totalCount = candidates.length;
    int blockedCount = 0;
    int unplayedFilterCount = 0;
    int highRatedFilterCount = 0;

    for (final show in candidates) {
      // Find valid sources for this show
      final validSources = show.sources.where((s) {
        // Must be unblocked
        if (catalog.getRating(s.id) == -1) return false;
        // Must match active filters (SBD, Matrix, etc.)
        if (isSourceAllowed != null && !isSourceAllowed(s)) {
          return false;
        }
        return true;
      }).toList();

      if (validSources.isEmpty) {
        blockedCount++;
        continue;
      }

      // We pick the first valid source as the representative for weighting
      final source = validSources.first;
      final rating = catalog.getRating(source.id);
      final isPlayed = catalog.isPlayed(source.id);

      // Filter by Settings
      if (settings.randomOnlyUnplayed && isPlayed) {
        unplayedFilterCount++;
        continue;
      }
      if (settings.randomOnlyHighRated && rating < 2) {
        highRatedFilterCount++;
        continue;
      }

      int weight = 10;
      if (settings.randomExcludePlayed && isPlayed) {
        weight = 0;
      } else if (rating == 3) {
        weight = 200; // Favorite shows are highly preferred
      } else if (rating == 2) {
        weight = 100; // High rated shows
      } else if (rating == 1) {
        weight = 40; // Rated shows
      } else if (rating == 0) {
        weight =
            isPlayed ? 10 : 60; // Unplayed is preferred over general played
      }

      if (weight > 0) {
        playCandidates.add(show);
        weights[show] = weight;
        selectedSourceMap[show] = source;
      }
    }

    if (playCandidates.isEmpty) {
      String msg = 'No shows match criteria.';
      if (highRatedFilterCount > 0 &&
          highRatedFilterCount + blockedCount == totalCount) {
        msg = 'No shows match "High Rated" filter.';
      } else if (unplayedFilterCount > 0 &&
          unplayedFilterCount + blockedCount == totalCount) {
        msg = 'No unplayed shows available.';
      } else if (blockedCount == totalCount) {
        msg = 'All available shows are blocked.';
      } else if (totalCount > 0) {
        msg = 'All shows filtered out by source settings.';
      }

      logger.w(
          'Random Selection: $msg (Filtered: $totalCount, Blocked: $blockedCount, Unplayed: $unplayedFilterCount, HighRated: $highRatedFilterCount)');
      return null;
    }

    int totalWeight = weights.values.fold(0, (sum, w) => sum + w);
    int randomWeight = _random.nextInt(totalWeight);
    int currentWeight = 0;
    Show? selectedShow;

    for (final show in playCandidates) {
      currentWeight += weights[show]!;
      if (randomWeight < currentWeight) {
        selectedShow = show;
        break;
      }
    }

    selectedShow ??= playCandidates.first;
    final sourceToPlay = selectedSourceMap[selectedShow]!;

    logger.i(
        'Weighted selection: ${selectedShow.date} (Weight: ${weights[selectedShow]}/$totalWeight) - Sources: ${selectedShow.sources.length}');

    return (show: selectedShow, source: sourceToPlay);
  }
}
