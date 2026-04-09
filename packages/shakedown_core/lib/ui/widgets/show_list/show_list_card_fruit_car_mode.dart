part of 'show_list_card.dart';

extension _ShowListCardFruitCarModeBuild on _ShowListCardState {
  Widget _buildFruitCarModeCardContent({
    required BuildContext context,
    required double borderRadius,
    required Color backgroundColor,
    required CardStyle style,
    required SettingsProvider settingsProvider,
    required ColorScheme colorScheme,
  }) {
    return buildFruitCarModeCardContent(
      context: context,
      show: widget.show,
      playingSource: widget.playingSource,
      isPlaying: widget.isPlaying,
      alwaysShowRatingInteraction: widget.alwaysShowRatingInteraction,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      buildBadge: _buildBadge,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      style: style,
      settingsProvider: settingsProvider,
      colorScheme: colorScheme,
    );
  }
}
