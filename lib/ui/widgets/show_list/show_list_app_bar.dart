import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/widgets/shakedown_title.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';

class ShowListAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Animation<double> randomPulseAnimation;
  final Animation<double> searchPulseAnimation;
  final bool isRandomShowLoading;
  final VoidCallback onRandomPlay;
  final VoidCallback onToggleSearch;
  final VoidCallback onTitleTap;
  final Color? backgroundColor;

  const ShowListAppBar({
    super.key,
    required this.randomPulseAnimation,
    required this.searchPulseAnimation,
    required this.isRandomShowLoading,
    required this.onRandomPlay,
    required this.onToggleSearch,
    required this.onTitleTap,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      title: GestureDetector(
        onTap: onTitleTap,
        child: const ShakedownTitle(
          fontSize: 16,
          animateOnStart: true,
          shakeDelay: Duration(milliseconds: 1700),
        ),
      ),
      actions: _buildActions(context),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final showListProvider = context.watch<ShowListProvider>();

    return [
      if (isRandomShowLoading)
        const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5)),
        )
      else if (settingsProvider.nonRandom)
        IconButton(
          icon: const Icon(Icons.playlist_play_rounded),
          onPressed: onRandomPlay,
          tooltip: 'Play Next Show',
        )
      else
        ScaleTransition(
          scale: randomPulseAnimation,
          child: IconButton(
            icon: const Icon(Icons.question_mark_rounded),
            onPressed: onRandomPlay,
            tooltip: 'Play Random Show',
          ),
        ),
      ScaleTransition(
        scale: searchPulseAnimation,
        child: IconButton(
          icon: const Icon(Icons.search_rounded),
          isSelected: showListProvider.isSearchVisible,
          style: showListProvider.isSearchVisible
              ? IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainer,
                  shape: CircleBorder(
                    side: BorderSide(color: colorScheme.outline),
                  ),
                )
              : null,
          onPressed: onToggleSearch,
        ),
      ),
      IconButton(
        icon: const Icon(Icons.settings_rounded),
        onPressed: () async {
          // Pause global clock before navigating to generic pages (Settings)
          // to prevent "visual jumps" when returning.
          try {
            context.read<AnimationController>().stop();
          } catch (_) {}

          await Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const SettingsScreen(),
              transitionDuration: Duration.zero,
            ),
          );

          // Resume clock on return
          if (context.mounted) {
            try {
              final controller = context.read<AnimationController>();
              if (!controller.isAnimating) controller.repeat();
            } catch (_) {}
          }
        },
      ),
    ];
  }
}
