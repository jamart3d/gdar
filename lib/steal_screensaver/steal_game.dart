import 'dart:async';
import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Color, Colors;
import 'package:shakedown/steal_screensaver/steal_banner.dart';
import 'package:shakedown/steal_screensaver/steal_config.dart';
import 'package:shakedown/steal_screensaver/steal_background.dart';
import 'package:shakedown/visualizer/audio_reactor.dart';
import 'package:shakedown/services/device_service.dart';

class StealGame extends FlameGame {
  StealConfig config;
  final DeviceService deviceService;
  final VoidCallback? onPaletteCycleRequested;

  AudioReactor? _audioReactor;
  StreamSubscription<AudioEnergy>? _energySubscription;
  StealBackground? _background;
  StealBanner? _banner;
  double _time = 0;
  AudioEnergy _currentEnergy = const AudioEnergy.zero();

  // Palette Cycling State
  double _accumulatedCycleEnergy = 0.0;
  double _lastCycleTime = 0.0;
  static const double kCycleEnergyThreshold = 100.0;
  static const double kMinCycleInterval = 10.0;

  StealGame({
    required this.config,
    AudioReactor? audioReactor,
    required this.deviceService,
    this.onPaletteCycleRequested,
  }) : _audioReactor = audioReactor;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _subscribeToReactor(_audioReactor);

    _background = StealBackground(config: config);
    add(_background!);

    // Banner renders above the shader layer
    _banner = StealBanner();
    add(_banner!);

    // Initialize banner with current config
    _applyBannerConfig(config);
  }

  void _subscribeToReactor(AudioReactor? reactor) {
    _energySubscription?.cancel();
    _energySubscription = null;
    if (reactor != null) {
      _energySubscription = reactor.energyStream.listen((energy) {
        _currentEnergy = energy;
      });
    }
  }

  void updateAudioReactor(AudioReactor? newReactor) {
    _audioReactor = newReactor;
    _subscribeToReactor(newReactor);
  }

  void updateBannerText(String text) {
    if (config.bannerText != text) {
      updateConfig(config.copyWith(bannerText: text));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Handle Palette Cycling
    if (onPaletteCycleRequested != null) {
      _accumulatedCycleEnergy += _currentEnergy.bass * dt * 20.0;
      _accumulatedCycleEnergy += dt * 2.0;

      if (_accumulatedCycleEnergy >= kCycleEnergyThreshold &&
          (_time - _lastCycleTime) >= kMinCycleInterval) {
        _accumulatedCycleEnergy = 0.0;
        _lastCycleTime = _time;
        onPaletteCycleRequested?.call();
      }
    }
  }

  void updateConfig(StealConfig newConfig) {
    config = newConfig;
    _background?.updateConfig(newConfig);
    _applyBannerConfig(newConfig);
  }

  void _applyBannerConfig(StealConfig cfg) {
    if (_banner == null) return;
    final paletteColors = StealConfig.palettes[cfg.palette] ??
        StealConfig.palettes['psychedelic']!;
    final paletteColor =
        paletteColors.isNotEmpty ? paletteColors.first : Colors.white;
    _banner!.updateBanner(
      cfg.bannerText,
      paletteColor,
      showBanner: cfg.showInfoBanner,
    );
  }

  @override
  void onRemove() {
    _energySubscription?.cancel();
    super.onRemove();
  }

  double get time => _time;
  AudioEnergy get currentEnergy => _currentEnergy;
}
