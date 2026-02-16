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

  bool _isProcessingRandomRequest = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_randomSubscription == null) {
      final audioProvider = context.read<AudioProvider>();
      _randomSubscription =
          audioProvider.randomShowRequestStream.listen((event) {
        debugPrint('TvDualPaneLayout: Random show request received!');
        if (_isProcessingRandomRequest) {
          debugPrint(
              'TvDualPaneLayout: Ignoring duplicate random show request.');
          return;
        }

        _isProcessingRandomRequest = true;

        // Sequence:
        // 1. Show the "Picking Random Show..." UI / Dice Animation
        // 2. Wait for visual confirmation (animations)
        // 3. Select the show in the list (scroll to it)
        // 4. Focus the track list
        // 5. Start playback

        // Stage 1: Wait for dice animation/logic (approx 1.2s)
        Future.delayed(const Duration(milliseconds: 1200), () {
          debugPrint('TvDualPaneLayout: Stage 1 complete (1200ms)');
          if (!mounted) {
            _isProcessingRandomRequest = false;
            return;
          }

          // Focus the selected show card directly
          _showListScreenKey.currentState?.focusShowByObject(event.show);
          setState(() => _focusedPane = 0); // Focus Show List pane

          // Stage 3: Wait for scroll to finish and user to see the show (2.0s)
          Future.delayed(const Duration(milliseconds: 2000), () {
            debugPrint('TvDualPaneLayout: Stage 2 complete (2000ms)');
            if (mounted) {
              setState(() => _focusedPane = 1); // Focus Track List pane (Right)

              // Focus the track list directly via key
              if (_playbackScreenKey.currentState != null) {
                _playbackScreenKey.currentState!.focusCurrentTrack();
              } else {
                _rightScrollbarFocusNode.requestFocus();
              }

              // Stage 4: Wait 2000ms after track list gets focus before starting playback
              Future.delayed(const Duration(milliseconds: 2000), () {
                debugPrint(
                    'TvDualPaneLayout: Stage 3 complete (2000ms), checking if playback needed');
                if (mounted) {
                  // Check if we are ALREADY playing the requested show/source
                  // This prevents double-playback if focus/tap triggered it early
                  final pending = audioProvider.pendingRandomShowRequest;
                  final currentShow = audioProvider.currentShow;
                  final currentSource = audioProvider.currentSource;
                  final isPlaying = audioProvider.isPlaying;

                  bool alreadyPlayingRequest = isPlaying &&
                      pending != null &&
                      currentShow?.name == pending.show.name &&
                      currentSource?.id == pending.source.id;

                  if (alreadyPlayingRequest) {
                    debugPrint(
                        'TvDualPaneLayout: Requested show is already playing. Skipping explicit playPendingSelection.');
                  } else {
                    debugPrint(
                        'TvDualPaneLayout: Calling playPendingSelection.');
                    audioProvider.playPendingSelection();
                  }

                  // Sequence complete, allow new requests
                  // Add a small buffer to ensure playback has definitely started/stabilized
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) _isProcessingRandomRequest = false;
                  });
                } else {
                  _isProcessingRandomRequest = false;
                }
              });
            } else {
              _isProcessingRandomRequest = false;
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
