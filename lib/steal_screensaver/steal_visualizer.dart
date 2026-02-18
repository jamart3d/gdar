import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:shakedown/steal_screensaver/steal_config.dart';
import 'package:shakedown/steal_screensaver/steal_game.dart';
import 'package:shakedown/visualizer/audio_reactor.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _game = StealGame(
      config: widget.config,
      audioReactor: widget.audioReactor,
      deviceService: Provider.of<DeviceService>(context, listen: false),
      onPaletteCycleRequested: _handlePaletteCycle,
    );
  }

  void _handlePaletteCycle() {
    final settings = context.read<SettingsProvider>();
    final palettes = StealConfig.palettes.keys.toList();
    final currentIndex = palettes.indexOf(settings.oilPalette);
    final nextIndex = (currentIndex + 1) % palettes.length;
    final nextPalette = palettes[nextIndex];
    settings.setOilPalette(nextPalette);
  }

  @override
  void didUpdateWidget(StealVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _game.updateConfig(widget.config);
    _game.updateBannerText(widget.config.bannerText);
    if (widget.audioReactor != oldWidget.audioReactor) {
      _game.updateAudioReactor(widget.audioReactor);
    }
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
