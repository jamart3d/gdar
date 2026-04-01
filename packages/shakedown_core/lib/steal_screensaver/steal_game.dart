import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Color, Colors;
import 'steal_banner.dart';
import 'steal_config.dart';
import 'steal_background.dart';
import 'steal_graph.dart';
import 'package:shakedown_core/visualizer/audio_reactor.dart';
import 'package:shakedown_core/services/device_service.dart';

class StealGame extends FlameGame {
  StealConfig config;
  final DeviceService deviceService;

  double _time = 0;
  AudioEnergy _currentEnergy = const AudioEnergy.zero();
  AudioReactor? _audioReactor;
  StreamSubscription? _energySubscription;

  StealBackground? _background;
  StealGraph? _graph;
  StealBanner? _banner;

  // -- Palette Cycling --------------------------------------------------------
  static const double _baseHoldMin = 20.0;
  static const double _baseHoldMax = 40.0;
  static const double _holdVariance = 0.3;

  final _rng = Random();
  double _cycleTimer = 0.0;
  double _holdDuration = 0.0;
  bool _cycling = false;
  String _lastPalette = '';
  double _beatPulse = 0.0;

  int? debugAudioSessionId;

  StealGame({
    required this.config,
    required this.deviceService,
    AudioReactor? audioReactor,
    this.debugAudioSessionId,
  }) : _audioReactor = audioReactor;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _subscribeToReactor(_audioReactor);

    _background = StealBackground(config: config)..priority = -10;
    await add(_background!);

    // Graph is added with priority 5 so it renders on top of the shader but behind text (priority 10)
    _graph = StealGraph()..priority = 5;
    await add(_graph!);

    _banner = StealBanner()..priority = 10;
    await add(_banner!);

    _applyBannerConfig(config);
    _applyGraphConfig(config);

    _lastPalette = config.palette;
    _resetHoldTimer();
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
    if (newReactor == null) {
      _currentEnergy = const AudioEnergy.zero();
      _beatPulse = 0.0;
    }
  }

  void updateBannerText(String text) {
    if (config.bannerText != text) {
      updateConfig(config.copyWith(bannerText: text));
    }
  }

  @override
  void update(double dt) {
    // Push current energy to graph BEFORE super.update() so StealGraph.update()
    // receives fresh data for this frame rather than being one frame behind.
    if (_graph != null) {
      _graph!.energy = _currentEnergy;
      _graph!.debugSessionId =
          _currentEnergy.debugAudioSessionId ?? debugAudioSessionId;
      _graph!.debugReactorConnected = _audioReactor != null;
    }

    super.update(dt);
    // Cap dt for the position-curve clock so dropped frames don't cause the
    // Lissajous target to leap forward and produce a visible logo "jump".
    // Other systems (smoothing, palette cycle, trail) receive real dt for
    // correct time-corrected behavior.
    _time += dt.clamp(0.0, 1.0 / 30.0);

    if (config.paletteCycle && !isWoodstockActive) {
      _tickCycle(dt);
    }

    _tickWoodstock(dt);
    _tickPulse(dt);
  }

  void _tickPulse(double dt) {
    if (config.audioGraphMode == 'corner_only') {
      _beatPulse = 0.0;
      return;
    }

    if (_currentEnergy.isBeat) {
      // Smooth attack avoids single-frame pop when beat flags flap.
      _beatPulse += (1.0 - _beatPulse) * (1.0 - exp(-14.0 * dt));
    } else {
      _beatPulse *= pow(0.04, dt).clamp(0.0, 1.0).toDouble();
      if (_beatPulse < 0.01) _beatPulse = 0.0;
    }
  }

  // -- Cycle logic ------------------------------------------------------------

  double get _speed => config.paletteTransitionSpeed.clamp(0.1, 20.0);
  double get _scaledHoldMin => _baseHoldMin / _speed;
  double get _scaledHoldMax => _baseHoldMax / _speed;

  void _resetHoldTimer() {
    final range = _scaledHoldMax - _scaledHoldMin;
    final variance = range * _holdVariance;
    final base = _scaledHoldMin + _rng.nextDouble() * range;
    _holdDuration = (base + (_rng.nextDouble() * 2 - 1) * variance).clamp(
      _scaledHoldMin * 0.5,
      _scaledHoldMax * 2.0,
    );
    _cycleTimer = 0.0;
    _cycling = false;
  }

  void _tickCycle(double dt) {
    _cycleTimer += dt;
    if (!_cycling && _cycleTimer >= _holdDuration) {
      _cycling = true;
      _triggerNextPalette();
    }
  }

  void _triggerNextPalette() {
    final keys = StealConfig.palettes.keys.toList();
    String next;
    if (keys.length <= 1) {
      next = keys.first;
    } else {
      final candidates = keys.where((k) => k != _lastPalette).toList();
      next = candidates[_rng.nextInt(candidates.length)];
    }
    _lastPalette = next;

    final newConfig = config.copyWith(palette: next);
    config = newConfig;

    _background?.updateConfig(newConfig);
    _applyBannerConfig(newConfig);

    _resetHoldTimer();
  }

  // -- Woodstock Mode ---------------------------------------------------------
  static const double _woodstockYellowDuration = 15.0;
  static const double _woodstockGreenDuration = 4 * 60 + 20.0;
  static const double _woodstockFadeDuration = 5.0;
  static const Color _woodstockYellow = Color(0xFFFFD700);
  static const Color _woodstockGreen = Color(0xFF00CC44);

  _WoodstockPhase _woodstockPhase = _WoodstockPhase.idle;
  double _woodstockTimer = 0.0;

  void triggerWoodstockMode() {
    if (_woodstockPhase != _WoodstockPhase.idle) return;
    _woodstockPhase = _WoodstockPhase.yellow;
    _woodstockTimer = 0.0;
    _applyWoodstockColors([_woodstockYellow], _woodstockFadeDuration);
  }

  void _tickWoodstock(double dt) {
    if (_woodstockPhase == _WoodstockPhase.idle) return;
    _woodstockTimer += dt;

    switch (_woodstockPhase) {
      case _WoodstockPhase.yellow:
        if (_woodstockTimer >= _woodstockYellowDuration) {
          _woodstockPhase = _WoodstockPhase.green;
          _woodstockTimer = 0.0;
          _applyWoodstockColors([_woodstockGreen], _woodstockFadeDuration);
        }
        break;
      case _WoodstockPhase.green:
        if (_woodstockTimer >= _woodstockGreenDuration) {
          _woodstockPhase = _WoodstockPhase.idle;
          _woodstockTimer = 0.0;
          _restoreNormalPalette();
        }
        break;
      case _WoodstockPhase.idle:
        break;
    }
  }

  void _applyWoodstockColors(List<Color> colors, double fadeDuration) {
    if (_banner != null) {
      _banner!.updateBanner(
        config.bannerText,
        colors.first,
        showBanner: config.showInfoBanner,
        venue: config.venue,
        date: config.date,
      );
    }
  }

  void _restoreNormalPalette() {
    final paletteColors =
        StealConfig.palettes[config.palette] ??
        (StealConfig.palettes.isNotEmpty
            ? StealConfig.palettes.values.first
            : [Colors.white]);
    _applyWoodstockColors(paletteColors, _woodstockFadeDuration * 2);
    _applyBannerConfig(config);
    _resetHoldTimer();
  }

  bool get isWoodstockActive => _woodstockPhase != _WoodstockPhase.idle;

  void updateConfig(StealConfig newConfig) {
    config = newConfig;
    _background?.updateConfig(newConfig);
    _applyBannerConfig(newConfig);
    _applyGraphConfig(newConfig);
  }

  void _applyGraphConfig(StealConfig cfg) {
    if (_graph == null) return;
    _graph!.graphMode = cfg.audioGraphMode;
    _graph!.isVisible = cfg.audioGraphMode != 'off';
  }

  void _applyBannerConfig(StealConfig cfg) {
    if (_banner == null) return;
    final paletteColors = StealConfig.palettes[cfg.palette] ?? [Colors.white];
    final rawColor = paletteColors.isNotEmpty
        ? paletteColors.first
        : Colors.white;

    final bannerColor = rawColor.computeLuminance() > 0.85
        ? Colors.white
        : rawColor;

    _banner!.updateBanner(
      cfg.bannerText,
      bannerColor,
      showBanner: cfg.showInfoBanner,
      venue: cfg.venue,
      date: cfg.date,
    );
  }

  double get time => _time;
  AudioEnergy get currentEnergy => _currentEnergy;

  /// Smoothed logo position in 0-1 UV space, driven by StealBackground.
  /// Used by StealBanner to keep rings locked to the logo center.
  Offset get smoothedLogoPos =>
      _background?.smoothedLogoPos ?? const Offset(0.5, 0.5);

  Offset get renderedLogoPos =>
      _background?.renderedLogoPos ?? const Offset(0.5, 0.5);

  /// Unified beat pulse factor (0.0 to 1.0) with exponential decay.
  double get beatPulse => _beatPulse;

  /// Unified pulse scale multiplier combining base scale and audio energy.
  /// Used to synchronize logo and banner expansion.
  double get pulseScale {
    if (config.audioGraphMode == 'corner_only' ||
        !config.enableAudioReactivity) {
      return 1.0;
    }

    final energy = switch (config.scaleSource) {
      -2 => 0.0,
      -1 => _currentEnergy.bass,
      _ => _currentEnergy.bands[config.scaleSource.clamp(0, 7)],
    };

    return (1.0 +
        energy * 0.2 * config.pulseIntensity * config.scaleMultiplier);
  }
}

enum _WoodstockPhase { idle, yellow, green }
