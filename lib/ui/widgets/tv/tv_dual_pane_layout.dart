import 'package:flutter/material.dart';
import 'package:shakedown/ui/screens/playback_screen.dart';
import 'package:shakedown/ui/screens/show_list_screen.dart';

class TvDualPaneLayout extends StatelessWidget {
  const TvDualPaneLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            const Expanded(
              flex: 3,
              child: ShowListScreen(isPane: true),
            ),
            const Expanded(
              flex: 7,
              child: PlaybackScreen(isPane: true),
            ),
          ],
        ),
      ),
    );
  }
}
