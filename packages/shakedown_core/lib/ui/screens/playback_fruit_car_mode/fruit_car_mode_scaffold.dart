part of '../playback_screen.dart';

extension _PlaybackScreenFruitCarModeScaffold on PlaybackScreenState {
  Widget _buildFruitCarModeScaffoldContent({
    required BuildContext context,
    required AudioProvider audioProvider,
    required Color backgroundColor,
    required Show currentShow,
    required Source currentSource,
    required double scaleFactor,
    required SettingsProvider settingsProvider,
  }) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        key: const ValueKey('fruit_car_mode_layout'),
        decoration: BoxDecoration(
          gradient: _fruitCarModeBackgroundGradient(context),
        ),
        child: Stack(
          children: [
            _buildFruitCarModeFloatingSpheres(
              context: context,
              settingsProvider: settingsProvider,
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: _fruitCarModePagePadding(context, scaleFactor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFruitCarModeHud(
                      context: context,
                      audioProvider: audioProvider,
                      currentSource: currentSource,
                      scaleFactor: scaleFactor,
                    ),
                    SizedBox(height: 18 * scaleFactor),
                    _buildFruitCarModeHero(
                      context: context,
                      audioProvider: audioProvider,
                      currentShow: currentShow,
                      currentSource: currentSource,
                      scaleFactor: scaleFactor,
                      settingsProvider: settingsProvider,
                    ),
                    SizedBox(height: 18 * scaleFactor),
                    _buildFruitCarModeProgress(
                      context: context,
                      audioProvider: audioProvider,
                      scaleFactor: scaleFactor,
                    ),
                    SizedBox(height: 4 * scaleFactor),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4 * scaleFactor,
                            ),
                            child: _buildFruitCarModeControls(
                              context: context,
                              audioProvider: audioProvider,
                              scaleFactor: scaleFactor,
                            ),
                          ),
                          SizedBox(height: 18 * scaleFactor),
                          Expanded(
                            child: SingleChildScrollView(
                              key: const ValueKey(
                                'fruit_car_mode_upcoming_scroll',
                              ),
                              padding: EdgeInsets.only(
                                bottom: 220 * scaleFactor,
                              ),
                              child: _buildFruitCarModeUpcomingTracks(
                                context: context,
                                audioProvider: audioProvider,
                                currentSource: currentSource,
                                scaleFactor: scaleFactor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showFruitTabBar
          ? FruitTabBar(
              selectedIndex: 0,
              onTabSelected: (index) =>
                  _handleFruitTabSelection(context, index),
            )
          : null,
    );
  }

  Widget _buildFruitCarModeFloatingSpheres({
    required BuildContext context,
    required SettingsProvider settingsProvider,
  }) {
    if (!settingsProvider.fruitFloatingSpheres) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: FloatingSpheresBackground(
            key: const ValueKey('fruit_car_mode_floating_spheres'),
            colorScheme: Theme.of(context).colorScheme,
            animate: !settingsProvider.performanceMode,
            sphereCount: SphereAmount.tiny,
          ),
        ),
      ),
    );
  }

  Widget _buildFruitCarModeHero({
    required BuildContext context,
    required AudioProvider audioProvider,
    required Show currentShow,
    required Source currentSource,
    required double scaleFactor,
    required SettingsProvider settingsProvider,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final String? locationText = currentSource.location;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentShow.venue,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _fruitCarModeTextStyle(
            scaleFactor: scaleFactor,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: -0.8,
            color: colorScheme.onSurface.withValues(alpha: 0.9),
          ),
        ),
        SizedBox(height: 8 * scaleFactor),
        if (locationText != null && locationText.isNotEmpty) ...[
          Text(
            locationText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _fruitCarModeTextStyle(
              scaleFactor: scaleFactor,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: 6 * scaleFactor),
        ],
        Text(
          fruitCarModeDateText(currentShow),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _fruitCarModeTextStyle(
            scaleFactor: scaleFactor,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
          ),
        ),
        SizedBox(height: 18 * scaleFactor),
        SizedBox(
          height: 52 * scaleFactor,
          child: ConditionalMarquee(
            key: ValueKey(audioProvider.currentTrack?.url ?? currentShow.key),
            text:
                audioProvider.currentTrack?.title ??
                (currentSource.tracks.isNotEmpty
                    ? currentSource.tracks.first.title
                    : 'Picking show...'),
            enableAnimation: settingsProvider.marqueeEnabled,
            velocity: 48.0,
            blankSpace: 72.0,
            pauseAfterRound: const Duration(milliseconds: 1200),
            fadingEdgeStartFraction: 0.03,
            fadingEdgeEndFraction: 0.08,
            style: _fruitCarModeTextStyle(
              scaleFactor: scaleFactor,
              fontSize: 46,
              fontWeight: FontWeight.w900,
              height: 0.92,
              letterSpacing: -2.0,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  LinearGradient _fruitCarModeBackgroundGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colorScheme.surface,
        colorScheme.surfaceContainerLowest,
        colorScheme.surface,
      ],
    );
  }

  EdgeInsets _fruitCarModePagePadding(
    BuildContext context,
    double scaleFactor,
  ) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return EdgeInsets.fromLTRB(
      16 * scaleFactor,
      math.max(8.0, topPadding * 0.15),
      16 * scaleFactor,
      0,
    );
  }

  TextStyle _fruitCarModeTextStyle({
    required double scaleFactor,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double height = 1.0,
    double letterSpacing = 0.0,
  }) {
    return TextStyle(
      fontFamily: FontConfig.resolve('Inter'),
      fontSize: fontSize * scaleFactor,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }
}
