import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/ui/screens/playback_screen.dart';
import 'package:shakedown/ui/screens/show_list_screen.dart';
import 'package:shakedown/ui/widgets/tv/tv_header.dart';

import 'package:shakedown/ui/widgets/tv/tv_exit_dialog.dart';
import 'package:provider/provider.dart';

import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/widgets/playback/playback_messages.dart';

class TvDualPaneLayout extends StatefulWidget {
  const TvDualPaneLayout({super.key});

  @override
  State<TvDualPaneLayout> createState() => _TvDualPaneLayoutState();
}

class _TvDualPaneLayoutState extends State<TvDualPaneLayout> {
  int _focusedPane = 0; // 0 for left (ShowList), 1 for right (Playback)
  final FocusNode _diceFocusNode = FocusNode();
  final FocusNode _gearsFocusNode = FocusNode();
  final FocusNode _rightScrollbarFocusNode = FocusNode();
  final FocusNode _showListScrollbarFocusNode = FocusNode();
  final GlobalKey<PlaybackScreenState> _playbackScreenKey = GlobalKey();
  final GlobalKey<ShowListScreenState> _showListScreenKey = GlobalKey();
  StreamSubscription? _randomSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_randomSubscription == null) {
      final audioProvider = context.read<AudioProvider>();
      _randomSubscription =
          audioProvider.randomShowRequestStream.listen((event) {
        // Stage 2: Wait for ShowList scroll animation to settle (visual continuity)
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;

          // Focus the selected show card directly
          _showListScreenKey.currentState?.focusShowByObject(event.show);

          // Stage 3: Wait 2000ms on the show card before switching panes
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (mounted) {
              setState(() {
                _focusedPane = 1; // Highlight Right Pane (Playback/Tracks)
              });
              // Focus the track list directly via key
              if (_playbackScreenKey.currentState != null) {
                _playbackScreenKey.currentState!.focusCurrentTrack();
              } else {
                _rightScrollbarFocusNode.requestFocus();
              }

              // Stage 4: Wait 2000ms after track list gets focus before starting playback
              Future.delayed(const Duration(milliseconds: 2000), () {
                if (mounted) {
                  audioProvider.playPendingSelection();
                }
              });
            }
          });
        });
      });
    }
  }

  @override
  void dispose() {
    _diceFocusNode.dispose();
    _gearsFocusNode.dispose();
    _rightScrollbarFocusNode.dispose();
    _showListScrollbarFocusNode.dispose();
    _randomSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    // We use a Stack to float the Playback Bar at the bottom
    return PopScope(
      canPop: !audioProvider.isPlaying,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitDialog(context);
      },
      child: Scaffold(
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
                        opacity: _focusedPane == 0
                            ? 1.0
                            : 0.2, // Increased dimming from 0.4
                        child: Column(
                          children: [
                            TvHeader(
                              autofocusDice: true,
                              diceFocusNode: _diceFocusNode,
                              gearsFocusNode: _gearsFocusNode,
                              onRandomPlay: () {
                                context
                                    .read<AudioProvider>()
                                    .playRandomShow(delayPlayback: true);
                              },
                              onLeft: () {
                                // Wrap around from Dice (far left) to Right Pane
                                if (audioProvider.currentShow != null) {
                                  if (_playbackScreenKey.currentState != null) {
                                    _playbackScreenKey.currentState!
                                        .focusCurrentTrack();
                                  } else {
                                    _rightScrollbarFocusNode.requestFocus();
                                  }
                                }
                              },
                              onRight: () {
                                // From Settings (far right of header), go DOWN to Track List
                                if (_playbackScreenKey.currentState != null) {
                                  _playbackScreenKey.currentState!
                                      .focusCurrentTrack();
                                } else {
                                  _rightScrollbarFocusNode.requestFocus();
                                }
                              },
                            ),
                            Expanded(
                              child: ShowListScreen(
                                key: _showListScreenKey,
                                isPane: true,
                                scrollbarFocusNode: _showListScrollbarFocusNode,
                                onFocusLeft: () {
                                  _diceFocusNode.requestFocus();
                                },
                              ),
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
                          Colors.white
                              .withValues(alpha: 0.15), // Increased from 0.08
                          Colors.white
                              .withValues(alpha: 0.15), // Increased from 0.08
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
                        opacity: _focusedPane == 1
                            ? 1.0
                            : 0.2, // Increased dimming from 0.4
                        child: PlaybackScreen(
                          key: _playbackScreenKey,
                          isPane: true,
                          scrollbarFocusNode: _rightScrollbarFocusNode,
                          onScrollbarRight: () {
                            // Wrap around from Right Scrollbar (far right) to Dice (far left)
                            _diceFocusNode.requestFocus();
                          },
                          onTrackListLeft: () {
                            // From Track List, go LEFT to the Show List scrollbar
                            _showListScrollbarFocusNode.requestFocus();
                          },
                          onTrackListRight: () {
                            // From Track List, go RIGHT to the Track List scrollbar
                            _rightScrollbarFocusNode.requestFocus();
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Playback Messages (Top Right - No Gap)
            if (settingsProvider.showPlaybackMessages)
              const Positioned(
                top: 0,
                right: 5,
                child: PlaybackMessages(
                  textAlign: TextAlign.right,
                  showDivider: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    TvExitDialog.show(
      context,
      onBackground: () {
        // Just hide the app, keep music playing
        SystemNavigator.pop();
      },
      onQuit: () {
        // Stop audio and hide app
        context.read<AudioProvider>().stopAndClear();
        SystemNavigator.pop();
      },
    );
  }
}
