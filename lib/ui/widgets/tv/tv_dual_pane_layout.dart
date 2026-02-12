import 'package:flutter/material.dart';
import 'package:shakedown/ui/screens/playback_screen.dart';
import 'package:shakedown/ui/screens/show_list_screen.dart';

class TvDualPaneLayout extends StatefulWidget {
  const TvDualPaneLayout({super.key});

  @override
  State<TvDualPaneLayout> createState() => _TvDualPaneLayoutState();
}

class _TvDualPaneLayoutState extends State<TvDualPaneLayout> {
  int _focusedPane = 0; // 0 for left (ShowList), 1 for right (Playback)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48.0),
        child: Row(
          children: [
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
                  child: const ShowListScreen(isPane: true),
                ),
              ),
            ),
            // Vertical Glass Divider
            Container(
              width: 1.0,
              height: double.infinity,
              margin:
                  const EdgeInsets.symmetric(vertical: 96.0, horizontal: 16.0),
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
    );
  }
}
