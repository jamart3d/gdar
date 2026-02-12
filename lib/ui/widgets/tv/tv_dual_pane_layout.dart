import 'package:flutter/material.dart';
import 'package:shakedown/ui/screens/playback_screen.dart';
import 'package:shakedown/ui/screens/show_list_screen.dart';
import 'package:shakedown/ui/widgets/tv/tv_header.dart';
import 'package:shakedown/ui/widgets/tv/tv_playback_bar.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';

class TvDualPaneLayout extends StatefulWidget {
  const TvDualPaneLayout({super.key});

  @override
  State<TvDualPaneLayout> createState() => _TvDualPaneLayoutState();
}

class _TvDualPaneLayoutState extends State<TvDualPaneLayout> {
  int _focusedPane = 0; // 0 for left (ShowList), 1 for right (Playback)

  @override
  Widget build(BuildContext context) {
    // We use a Stack to float the Playback Bar at the bottom
    return Scaffold(
      body: Stack(
        children: [
          // Main Dual-Pane Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48.0),
            child: Row(
              children: [
                // Left Pane: Header + Show List
                Expanded(
                  flex: 1,
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      if (hasFocus) setState(() => _focusedPane = 0);
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      opacity: _focusedPane == 0 ? 1.0 : 0.4,
                      child: Column(
                        children: [
                          TvHeader(
                            isRandomShowLoading:
                                context.watch<ShowListProvider>().isLoading,
                            onRandomPlay: () {
                              context.read<AudioProvider>().playRandomShow();
                            },
                          ),
                          const Expanded(
                            child: ShowListScreen(isPane: true),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Vertical Glass Divider
                Container(
                  width: 1.0,
                  height: double.infinity,
                  margin: const EdgeInsets.symmetric(
                      vertical: 96.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // Right Pane: Playback / Track List
                Expanded(
                  flex: 1,
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      if (hasFocus) setState(() => _focusedPane = 1);
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      opacity: _focusedPane == 1 ? 1.0 : 0.4,
                      child: const PlaybackScreen(isPane: true),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating Playback Bar (Bottom Center)
          const Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: TvPlaybackBar(),
            ),
          ),
        ],
      ),
    );
  }
}
