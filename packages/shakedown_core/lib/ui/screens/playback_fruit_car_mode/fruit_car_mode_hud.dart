part of '../playback_screen.dart';

extension _PlaybackScreenFruitCarModeHud on PlaybackScreenState {
  Widget _buildFruitCarModeHud({
    required BuildContext context,
    required AudioProvider audioProvider,
    required Source currentSource,
    required double scaleFactor,
  }) {
    final chipRowHeight = _fruitCarModeChipCardHeight(scaleFactor);

    return GestureDetector(
      key: const ValueKey('fruit_car_mode_chip_row'),
      behavior: HitTestBehavior.opaque,
      onTap: toggleFruitCarModeHud,
      child: SizedBox(
        height: chipRowHeight,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.centerLeft,
            children: [...previousChildren, ?currentChild],
          ),
          child: _fruitCarModeHudShowsMeta
              ? _buildFruitCarModeHudMeta(
                  context: context,
                  currentSource: currentSource,
                  scaleFactor: scaleFactor,
                  chipRowHeight: chipRowHeight,
                )
              : _buildFruitCarModeHudStats(
                  context: context,
                  audioProvider: audioProvider,
                  scaleFactor: scaleFactor,
                ),
        ),
      ),
    );
  }

  Widget _buildFruitCarModeHudMeta({
    required BuildContext context,
    required Source currentSource,
    required double scaleFactor,
    required double chipRowHeight,
  }) {
    final catalog = CatalogService();
    final rating = catalog.getRating(currentSource.id);
    final isPlayed = catalog.isPlayed(currentSource.id);

    return SizedBox.expand(
      key: const ValueKey('fruit_car_mode_chip_row_meta'),
      child: Row(
        children: [
          SizedBox(
            width: 220 * scaleFactor,
            height: chipRowHeight,
            child: Semantics(
              button: true,
              label: 'Rate source ${currentSource.id}',
              child: GestureDetector(
                key: const ValueKey('fruit_car_mode_rating_zone'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _showFruitCarModeRatingDialog(
                  context,
                  currentSource: currentSource,
                  catalog: catalog,
                  rating: rating,
                  isPlayed: isPlayed,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12 * scaleFactor),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IgnorePointer(
                      child: RatingControl(
                        rating: rating,
                        isPlayed: isPlayed,
                        compact: true,
                        size: 56 * scaleFactor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 10 * scaleFactor),
          Expanded(
            child: _buildFruitCarModeMetaDetails(
              context: context,
              currentSource: currentSource,
              scaleFactor: scaleFactor,
              chipRowHeight: chipRowHeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFruitCarModeMetaDetails({
    required BuildContext context,
    required Source currentSource,
    required double scaleFactor,
    required double chipRowHeight,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final String sourceLabel = (currentSource.src ?? '').toUpperCase();
    final bool hasSourceLabel = sourceLabel.isNotEmpty;

    return SizedBox(
      height: chipRowHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          key: const ValueKey('fruit_car_mode_meta_stack'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasSourceLabel)
              Text(
                sourceLabel,
                key: const ValueKey('fruit_car_mode_src_label'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _fruitCarModeTextStyle(
                  scaleFactor: scaleFactor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: 0.9,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.92),
                ),
              ),
            if (hasSourceLabel) SizedBox(height: 4 * scaleFactor),
            Text(
              currentSource.id,
              key: const ValueKey('fruit_car_mode_shnid_label'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _fruitCarModeTextStyle(
                scaleFactor: scaleFactor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: 0.2,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFruitCarModeHudStats({
    required BuildContext context,
    required AudioProvider audioProvider,
    required double scaleFactor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox.expand(
      key: const ValueKey('fruit_car_mode_chip_row_stats'),
      child: StreamBuilder<HudSnapshot>(
        stream: audioProvider.hudSnapshotStream,
        initialData: audioProvider.currentHudSnapshot,
        builder: (context, snapshot) {
          final liveHud = snapshot.data ?? HudSnapshot.empty();
          final hud = _resolveFruitCarModeHudSnapshot(
            liveHud: liveHud,
            isPlaying: liveHud.isPlaying,
          );
          final headroomDuration =
              parseFruitCarModeDurationText(hud.headroom) ?? Duration.zero;
          final headroomFill = computeFruitCarModeHeadroomFill(
            headroom: headroomDuration,
          );
          final nextBufferedDuration =
              parseFruitCarModeDurationText(hud.nextBuffered) ?? Duration.zero;
          final nextTrackTotal = audioProvider.audioPlayer.nextTrackTotal;
          final nextTrackFill = computeFruitCarModeNextTrackFill(
            nextBuffered: nextBufferedDuration,
            nextTotal: nextTrackTotal,
          );

          return Row(
            children: [
              Expanded(
                child: _FruitCarModeStatCard(
                  label: 'DRIFT',
                  value: hud.drift,
                  accentColor: colorScheme.primary,
                  scaleFactor: scaleFactor,
                ),
              ),
              SizedBox(width: 6 * scaleFactor),
              Expanded(
                child: _FruitCarModeStatCard(
                  label: 'HEADROOM',
                  value: hud.headroom,
                  accentColor: colorScheme.secondary,
                  scaleFactor: scaleFactor,
                  fillFraction: headroomFill,
                ),
              ),
              SizedBox(width: 6 * scaleFactor),
              Expanded(
                child: _FruitCarModeStatCard(
                  label: 'NEXT',
                  value: hud.nextBuffered,
                  accentColor: colorScheme.tertiary,
                  scaleFactor: scaleFactor,
                  fillFraction: nextTrackFill,
                ),
              ),
              SizedBox(width: 6 * scaleFactor),
              Expanded(
                child: _FruitCarModeStatCard(
                  label: 'LAST GAP',
                  value: hud.lastGapMs == null
                      ? '--'
                      : '${hud.lastGapMs!.toStringAsFixed(0)}ms',
                  accentColor: colorScheme.onSurface,
                  scaleFactor: scaleFactor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
