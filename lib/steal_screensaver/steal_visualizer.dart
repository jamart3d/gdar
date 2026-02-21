import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:shakedown/steal_screensaver/steal_config.dart';
import 'package:shakedown/steal_screensaver/steal_game.dart';
import 'package:shakedown/visualizer/easter_egg_detector.dart';
import 'package:shakedown/visualizer/audio_reactor.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:provider/provider.dart';

class StealVisualizer extends StatefulWidget {
  final StealConfig config;
  final AudioReactor? audioReactor;
  final VoidCallback? onExit;

  const StealVisualizer({
    super.key,
    required this.config,
    this.audioReactor,
    this.onExit,
  });

  @override
  State<StealVisualizer> createState() => _StealVisualizerState();
}

class _StealVisualizerState extends State<StealVisualizer> {
  late StealGame _game;
  late EasterEggDetector _easterEggDetector;

  @override
  void initState() {
    super.initState();
    _game = StealGame(
      config: widget.config,
      audioReactor: widget.audioReactor,
      deviceService: Provider.of<DeviceService>(context, listen: false),
    );

    _easterEggDetector = EasterEggDetector(
      onEasterEggTriggered: (egg) {
        if (egg == EasterEgg.woodstockMode) {
          _game.triggerWoodstockMode();
        }
      },
    );

    // Check immediately on launch — if it's already 4:20 when screensaver opens
    if (EasterEggDetector.isWoodstockTime()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _game.triggerWoodstockMode();
      });
    }

    // Push initial banner text — didUpdateWidget won't fire on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _game.updateBannerText(widget.config.bannerText);
    });
  }

  @override
  void didUpdateWidget(StealVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only push config into the game when something actually changed.
    // StealConfig implements == so this is a value comparison, not identity.
    // This prevents AudioProvider position ticks from triggering spurious
    // updateConfig calls that were causing the translation jolt.
    if (widget.config != oldWidget.config) {
      _game.updateConfig(widget.config);
    }
    if (widget.config.bannerText != oldWidget.config.bannerText) {
      _game.updateBannerText(widget.config.bannerText);
    }
    if (widget.audioReactor != oldWidget.audioReactor) {
      _game.updateAudioReactor(widget.audioReactor);
    }
  }

  @override
  void dispose() {
    _easterEggDetector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onExit,
      behavior: HitTestBehavior.opaque,
      child: GameWidget(
        game: _game,
        loadingBuilder: (context) => const ColoredBox(color: Colors.black),
        backgroundBuilder: (context) => Container(color: Colors.black),
      ),
    );
  }
}
