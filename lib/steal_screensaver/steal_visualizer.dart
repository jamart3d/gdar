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
    // We can't check settings.oilPaletteCycle directly if it's not and-ed with a check for Steal Mode
    // But since this is ONLY for the Steal screensaver, we can assume it's relevant if enabled globally.
    // For now, I'll just keep the existing settings logic logic.

    final palettes = StealConfig.palettes.keys.toList();
    final currentIndex = palettes.indexOf(settings.oilPalette);
    final nextIndex = (currentIndex + 1) % palettes.length;
    final nextPalette = palettes[nextIndex];

    settings.setOilPalette(nextPalette);
  }

  @override
  void didUpdateWidget(StealVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config != oldWidget.config) {
      _game.updateConfig(widget.config);
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
