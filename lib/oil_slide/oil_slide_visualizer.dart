import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:shakedown/oil_slide/oil_slide_config.dart';
import 'package:shakedown/oil_slide/oil_slide_audio_reactor.dart';
import 'package:shakedown/oil_slide/oil_slide_game.dart';
import 'package:shakedown/oil_slide/easter_egg_detector.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:provider/provider.dart';

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
  EasterEggDetector? _easterEggDetector;

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.config;
    _game = OilSlideGame(
      config: _currentConfig,
      audioReactor: widget.audioReactor,
      deviceService: Provider.of<DeviceService>(context, listen: false),
    );

    if (widget.enableEasterEggs) {
      _easterEggDetector = EasterEggDetector(
        onEasterEggTriggered: _handleEasterEgg,
      );
    }
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
    _easterEggDetector?.dispose();
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
      case EasterEgg.woodstockMode:
        // Trigger special Woodstock-themed palette
        final newConfig = _currentConfig.copyWith(palette: 'cosmic');
        _handleConfigChanged(newConfig);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onExit,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Main visualizer
          GameWidget(
            game: _game,
          ),
        ],
      ),
    );
  }
}
