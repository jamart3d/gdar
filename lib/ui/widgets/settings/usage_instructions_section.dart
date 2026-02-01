import 'package:flutter/material.dart';
import 'package:shakedown/ui/widgets/section_card.dart';
import 'package:shakedown/ui/widgets/show_list/animated_dice_icon.dart';

class UsageInstructionsSection extends StatelessWidget {
  final double scaleFactor;
  final bool initiallyExpanded;

  const UsageInstructionsSection({
    super.key,
    required this.scaleFactor,
    required this.initiallyExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      scaleFactor: scaleFactor,
      title: 'Usage Instructions',
      icon: Icons.help_outline,
      initiallyExpanded: initiallyExpanded,
      children: [
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: SizedBox(
            width: 24,
            height: 24,
            child: FittedBox(
              child: AnimatedDiceIcon(
                onPressed: () {}, // Dummy callback to enable button
                isLoading: false, // Match idle AppBar speed
                changeFaces: false, // Don't change faces, just spin
                tooltip: 'Random Selection',
              ),
            ),
          ),
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Random Selection',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: Text.rich(
            TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12.0 * scaleFactor),
              children: const [
                TextSpan(
                    text: 'Tap', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        ' the dice icon in the app bar to play a random show. Selection respects "Random\u00A0Playback"\u00A0settings.\n'),
                TextSpan(
                    text: 'Long-press',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        ' a show card to play a random source from\u00A0that\u00A0show. If source filtering highest shnid only is off.'),
              ],
            ),
          ),
          isThreeLine: true,
        ),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.playlist_play_rounded),
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Auto-Play Modes',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: Text.rich(
            TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12.0 * scaleFactor),
              children: const [
                TextSpan(
                    text: 'Enable',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        ' "Play Random on Completion" for continuous radio-style playback. Toggle "Random" OFF for sequential playback (plays next\u00A0show).'),
              ],
            ),
          ),
        ),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.play_circle_outline_rounded),
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Player Controls',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: Text.rich(
            TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12.0 * scaleFactor),
              children: const [
                TextSpan(
                    text: 'Tap', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        ' the mini-player to open the full playback\u00A0screen.\n'),
                TextSpan(
                    text: 'Long-press',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        ' the mini-player to stop playback and clear\u00A0the\u00A0queue.'),
              ],
            ),
          ),
          isThreeLine: true,
        ),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.search_rounded),
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Search',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: Text.rich(
            TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12.0 * scaleFactor),
              children: const [
                TextSpan(
                    text: 'Tap', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        ' the search icon in the app bar to filter shows by venue\u00A0or\u00A0date. Or paste a shared link!'),
              ],
            ),
          ),
        ),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.star_rate_rounded),
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Rate Show',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: Text.rich(
            TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12.0 * scaleFactor),
              children: const [
                TextSpan(
                    text: 'Tap', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        ' the stars icon on a show card to\u00A0rate\u00A0it.'),
              ],
            ),
          ),
        ),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.block_rounded),
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Quick Block',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: Text.rich(
            TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12.0 * scaleFactor),
              children: const [
                TextSpan(
                    text: 'Swipe left',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        ' on a show card (or source) to quickly block it\u00A0(-1\u00A0rating).'),
              ],
            ),
          ),
        ),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.touch_app_rounded),
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Expand Show',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: Text.rich(
            TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12.0 * scaleFactor),
              children: const [
                TextSpan(
                    text: 'Tap', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        ' a show card to see available sources (SHNIDs) (if Source Filtering\u00A0-\u00A0Highest\u00A0SHNID\u00A0is\u00A0off).'),
              ],
            ),
          ),
        ),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.link_rounded),
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('View Source Page',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: Text.rich(
            TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12.0 * scaleFactor),
              children: const [
                TextSpan(
                    text: 'Tap', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        ' a source ID (SHNID) to open the Internet Archive\u00A0page.'),
              ],
            ),
          ),
        ),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.copy_rounded),
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Share Track with Friends',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: Text.rich(
            TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12.0 * scaleFactor),
              children: const [
                TextSpan(
                    text: 'Tap', style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        ' the share icon on the playback screen to copy track details to your clipboard. Send this to a friend!'),
              ],
            ),
          ),
        ),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.content_paste_rounded),
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Play from Shared Link',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: Text.rich(
            TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12.0 * scaleFactor),
              children: const [
                TextSpan(
                    text: 'Paste',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        ' a shared track link from your clipboard into search to jump directly to it.'),
              ],
            ),
          ),
        ),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.healing_rounded),
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Buffer Agent',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: Text.rich(
            TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12.0 * scaleFactor),
              children: const [
                TextSpan(
                    text: 'Auto-heals',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        ' playback when stuck buffering, and auto-resumes when connection\u00A0returns.'),
              ],
            ),
          ),
        ),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.download_for_offline_rounded),
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Advanced Cache',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: Text.rich(
            TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12.0 * scaleFactor),
              children: const [
                TextSpan(
                    text: 'Pre-caches',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                    text:
                        ' entire shows to ensure uninterrupted playback during deep sleep or poor connectivity.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
