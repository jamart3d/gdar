import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown_core/ui/screens/playback_screen.dart';
import 'package:shakedown_core/ui/screens/show_list_screen.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_header.dart';

import 'package:shakedown_core/ui/widgets/tv/tv_exit_dialog.dart';
import 'package:provider/provider.dart';

import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/ui/widgets/playback/playback_messages.dart';

// TV Remote Control Intents
class TvPlayPauseIntent extends Intent {
  const TvPlayPauseIntent();
}

class TvNextTrackIntent extends Intent {
  const TvNextTrackIntent();
}

class TvPreviousTrackIntent extends Intent {
  const TvPreviousTrackIntent();
}

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
  StreamSubscription? _focusSubscription;

  bool _isProcessingRandomRequest = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_randomSubscription == null) {
      final audioProvider = context.read<AudioProvider>();
      _randomSubscription = audioProvider.randomShowRequestStream.listen((
        event,
      ) {
        debugPrint('TvDualPaneLayout: Random show request received!');
        if (_isProcessingRandomRequest) {
          debugPrint(
            'TvDualPaneLayout: Ignoring duplicate random show request.',
          );
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
              _focusRightPane();

              // Stage 4: Wait 2000ms after track list gets focus before starting playback
              Future.delayed(const Duration(milliseconds: 2000), () {
                debugPrint(
                  'TvDualPaneLayout: Stage 3 complete (2000ms), checking if playback needed',
                );
                if (mounted) {
                  // Check if we are ALREADY playing the requested show/source
                  // This prevents double-playback if focus/tap triggered it early
                  final pending = audioProvider.pendingRandomShowRequest;
                  final currentShow = audioProvider.currentShow;
                  final currentSource = audioProvider.currentSource;
                  final isPlaying = audioProvider.isPlaying;

                  bool alreadyPlayingRequest =
                      isPlaying &&
                      pending != null &&
                      audioProvider.currentTrack !=
                          null && // Ensures we are actually playing THIS show, not the prev one during transitions.
                      currentShow?.name == pending.show.name &&
                      currentSource?.id == pending.source.id;

                  if (alreadyPlayingRequest) {
                    debugPrint(
                      'TvDualPaneLayout: Requested show is already playing. Skipping explicit playPendingSelection.',
                    );
                  } else {
                    debugPrint(
                      'TvDualPaneLayout: Calling playPendingSelection.',
                    );
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

    if (_focusSubscription == null) {
      final audioProvider = context.read<AudioProvider>();
      _focusSubscription = audioProvider.playbackFocusRequestStream.listen((_) {
        debugPrint('TvDualPaneLayout: Playback focus requested!');
        if (mounted) {
          _focusRightPane();
        }
      });
    }
  }

  void _focusRightPane() {
    if (!mounted) return;
    setState(() => _focusedPane = 1);

    // Only request physical focus if we are the current route.
    // This prevents background focus-stealing during track changes while in Settings.
    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    if (!isCurrent) return;

    // Give it a frame to ensure AudioProvider state has propagated to PlaybackScreen
    // and that its internal track list logic has updated its indices.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_playbackScreenKey.currentState != null) {
        _playbackScreenKey.currentState!.focusCurrentTrack();
      } else {
        _rightScrollbarFocusNode.requestFocus();
      }
    });
  }

  void _focusLeftPane() {
    if (!mounted) return;
    setState(() => _focusedPane = 0);

    final isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    if (!isCurrent) return;
    _diceFocusNode.requestFocus();
  }

  void _togglePane() {
    if (_focusedPane == 0) {
      _focusRightPane();
    } else {
      _focusLeftPane();
    }
  }

  @override
  void dispose() {
    _diceFocusNode.dispose();
    _gearsFocusNode.dispose();
    _rightScrollbarFocusNode.dispose();
    _showListScrollbarFocusNode.dispose();
    _randomSubscription?.cancel();
    _focusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();

    // We use a Stack to float the Playback Bar at the bottom
    return PopScope(
      canPop: !audioProvider.isPlaying,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If in playback pane, BACK goes back to show list instead of exiting
        if (_focusedPane == 1) {
          _focusLeftPane();
        } else {
          _showExitDialog(context);
        }
      },
      child: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.mediaPlayPause):
              const TvPlayPauseIntent(),
          LogicalKeySet(LogicalKeyboardKey.mediaPlay):
              const TvPlayPauseIntent(),
          LogicalKeySet(LogicalKeyboardKey.mediaPause):
              const TvPlayPauseIntent(),
          LogicalKeySet(LogicalKeyboardKey.mediaTrackNext):
              const TvNextTrackIntent(),
          LogicalKeySet(LogicalKeyboardKey.mediaTrackPrevious):
              const TvPreviousTrackIntent(),
          LogicalKeySet(LogicalKeyboardKey.tab): const _SwitchPaneIntent(),
          LogicalKeySet(LogicalKeyboardKey.keyS): const _SwitchPaneIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            TvPlayPauseIntent: CallbackAction<TvPlayPauseIntent>(
              onInvoke: (intent) {
                final ap = context.read<AudioProvider>();
                if (ap.isPlaying) {
                  ap.pause();
                } else {
                  ap.resume();
                }
                return null;
              },
            ),
            TvNextTrackIntent: CallbackAction<TvNextTrackIntent>(
              onInvoke: (intent) {
                context.read<AudioProvider>().seekToNext();
                return null;
              },
            ),
            TvPreviousTrackIntent: CallbackAction<TvPreviousTrackIntent>(
              onInvoke: (intent) {
                context.read<AudioProvider>().seekToPrevious();
                return null;
              },
            ),
            _SwitchPaneIntent: CallbackAction<_SwitchPaneIntent>(
              onInvoke: (intent) {
                _togglePane();
                return null;
              },
            ),
          },
          child: Scaffold(
            primary: false,
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Main Dual-Pane Content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0.0,
                    vertical: 12.0,
                  ),
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
                            duration: const Duration(milliseconds: 80),
                            curve: Curves.fastOutSlowIn,
                            opacity: _focusedPane == 0
                                ? 1.0
                                : 0.3, // Increased visibility of inactive pane just slightly
                            child: Column(
                              children: [
                                TvHeader(
                                  isActive: _focusedPane == 0,
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
                                      _focusRightPane();
                                    }
                                  },
                                  onRight: () {
                                    // From Settings (far right of header), go DOWN to Track List
                                    _focusRightPane();
                                  },
                                ),
                                Expanded(
                                  child: ShowListScreen(
                                    key: _showListScreenKey,
                                    isPane: true,
                                    scrollbarFocusNode:
                                        _showListScrollbarFocusNode,
                                    onFocusLeft: () {
                                      _diceFocusNode.requestFocus();
                                    },
                                    onFocusPlayback: _focusRightPane,
                                  ),
                                ),
                              ],
                            ),
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
                            duration: const Duration(milliseconds: 80),
                            curve: Curves.fastOutSlowIn,
                            opacity: _focusedPane == 1
                                ? 1.0
                                : 0.3, // Match left pane dimming
                            child: PlaybackScreen(
                              key: _playbackScreenKey,
                              isPane: true,
                              isActive: _focusedPane == 1,
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
                // Playback Status + Messages (Top Right - No Gap)
                const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: 0, right: 3),
                    child: PlaybackMessages(
                      textAlign: TextAlign.right,
                      showDivider: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

class _SwitchPaneIntent extends Intent {
  const _SwitchPaneIntent();
}
