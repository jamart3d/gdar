import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:shakedown/oil_slide/oil_slide_config.dart';
import 'package:shakedown/oil_slide/oil_slide_audio_reactor.dart';
import 'package:shakedown/oil_slide/oil_slide_game.dart';
import 'package:shakedown/oil_slide/ghost_menu.dart';
import 'package:shakedown/oil_slide/easter_egg_detector.dart';

/// Main oil_slide visualizer widget.
///
/// This widget integrates the Flame Engine game loop with the oil_slide
/// configuration, audio reactivity system, and Ghost Menu overlay.
class OilSlideVisualizer extends StatefulWidget {
  final OilSlideConfig config;
  final OilSlideAudioReactor? audioReactor;
  final VoidCallback? onExit;
  final bool kioskMode;
  final bool enableEasterEggs;

  const OilSlideVisualizer({
    super.key,
    required this.config,
    this.audioReactor,
    this.onExit,
    this.kioskMode = false,
    this.enableEasterEggs = true,
  });

  @override
  State<OilSlideVisualizer> createState() => _OilSlideVisualizerState();
}

class _OilSlideVisualizerState extends State<OilSlideVisualizer> {
  late OilSlideGame _game;
  late OilSlideConfig _currentConfig;

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.config;
    _game = OilSlideGame(
      config: _currentConfig,
      audioReactor: widget.audioReactor,
    );
  }

  @override
  void didUpdateWidget(OilSlideVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config != oldWidget.config) {
      setState(() {
        _currentConfig = widget.config;
      });
      _game.updateConfig(_currentConfig);
    }
  }

  @override
  void dispose() {
    widget.audioReactor?.stop();
    super.dispose();
  }

  void _handleConfigChanged(OilSlideConfig newConfig) {
    setState(() {
      _currentConfig = newConfig;
    });
    _game.updateConfig(newConfig);
  }

  void _handleEasterEgg(EasterEgg egg) {
    // Handle easter egg triggers
    switch (egg) {
      case EasterEgg.konamiCode:
        // Could trigger special palette or effect
        // For now, just cycle to a fun palette
        final newConfig = _currentConfig.copyWith(palette: 'psychedelic');
        _handleConfigChanged(newConfig);
        break;
      case EasterEgg.woodstockMode:
        // Trigger special Woodstock-themed palette
        final newConfig = _currentConfig.copyWith(palette: 'cosmic');
        _handleConfigChanged(newConfig);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main visualizer
        GameWidget(
          game: _game,
        ),

        // Ghost Menu overlay
        GhostMenu(
          config: _currentConfig,
          onConfigChanged: _handleConfigChanged,
          onExit: widget.onExit,
          kioskMode: widget.kioskMode,
          enableEasterEggs: widget.enableEasterEggs,
          onEasterEgg: _handleEasterEgg,
        ),
      ],
    );
  }
}
