part of 'playback_screen.dart';

extension _PlaybackScreenFruitCarModeBuild on PlaybackScreenState {
  Widget _buildFruitCarModeScaffold({
    required BuildContext context,
    required AudioProvider audioProvider,
    required Color backgroundColor,
    required Show currentShow,
    required Source currentSource,
    required double scaleFactor,
    required SettingsProvider settingsProvider,
  }) {
    return _buildFruitCarModeScaffoldContent(
      context: context,
      audioProvider: audioProvider,
      backgroundColor: backgroundColor,
      currentShow: currentShow,
      currentSource: currentSource,
      scaleFactor: scaleFactor,
      settingsProvider: settingsProvider,
    );
  }

  Future<void> _showFruitCarModeRatingDialog(
    BuildContext context, {
    required Source currentSource,
    required CatalogService catalog,
    required int rating,
    required bool isPlayed,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => RatingDialog(
        initialRating: rating,
        sourceId: currentSource.id,
        sourceUrl: currentSource.tracks.firstOrNull?.url,
        isPlayed: isPlayed,
        onRatingChanged: (newRating) {
          catalog.setRating(currentSource.id, newRating);
        },
        onPlayedChanged: (newIsPlayed) {
          if (newIsPlayed != catalog.isPlayed(currentSource.id)) {
            catalog.togglePlayed(currentSource.id);
          }
        },
      ),
    );
  }

  HudSnapshot _resolveFruitCarModeHudSnapshot({
    required HudSnapshot liveHud,
    required bool isPlaying,
  }) {
    final baseHud = isPlaying
        ? (_fruitCarModeFrozenHud = liveHud)
        : (_fruitCarModeFrozenHud ?? liveHud);

    final liveGap = baseHud.lastGapMs;
    if (liveGap != null && liveGap.isFinite && liveGap > 0) {
      _fruitCarModeLastMeasuredGapMs = liveGap;
      return baseHud;
    }

    final cachedGap = _fruitCarModeLastMeasuredGapMs;
    if (cachedGap != null && cachedGap.isFinite) {
      return baseHud.copyWith(lastGapMs: cachedGap);
    }

    return baseHud;
  }

  void _seekFruitCarModeProgress({
    required AudioProvider audioProvider,
    required double trackWidth,
    required int totalMs,
    required double localDx,
  }) {
    if (totalMs <= 0 || trackWidth <= 0) {
      return;
    }

    final normalized = (localDx / trackWidth).clamp(0.0, 1.0);
    audioProvider.seek(Duration(milliseconds: (normalized * totalMs).round()));
  }
}
