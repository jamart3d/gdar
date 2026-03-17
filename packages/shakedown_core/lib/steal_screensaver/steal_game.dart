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

  // -- Trail position ring buffer ---------------------------------------------
  // Stores recent smoothed logo positions for ghost slice rendering.
  // Store recent slices for ghost trails. Capacity currently 16.
  static const int _trailBufferCapacity = 16;
  final List<Offset> _trailBuffer = List.filled(
    _trailBufferCapacity,
    const Offset(0.5, 0.5),
  );
  int _trailHead = 0;
  int _trailFrameCount = 0;

  /// Returns up to [count] trail positions, newest first, with temporal interpolation
  /// to eliminate "stepping" as the logo moves.
  List<Offset> getTrailPositions(int count) {
    final interval = (1 + (config.logoTrailLength * 14.5).round()).clamp(1, 30);
    final frac = _trailFrameCount / interval.toDouble();

    final clamped = count.clamp(0, _trailBufferCapacity - 1);
    final result = <Offset>[];

    // Position 0 is always the "live" position (i=0)
    result.add(smoothedLogoPos);

    if (clamped <= 1) return result;

    for (int i = 1; i < clamped; i++) {
      // Find the two buffer indices to interpolate between
      // If i=1 (first ghost), we want it to be at 'interval' frames ago.
      // Current head is 'frameCount' frames ago.
      // k is the offset relative to head in samples.
      final findK = i - frac;
      final k = findK.floor();
      final t = findK - k;

      final idx1 =
          ((_trailHead - k) % _trailBufferCapacity + _trailBufferCapacity) %
          _trailBufferCapacity;
      final idx2 =
          ((_trailHead - (k + 1)) % _trailBufferCapacity +
              _trailBufferCapacity) %
          _trailBufferCapacity;

      final p1 = _trailBuffer[idx1];
      final p2 = _trailBuffer[idx2];

      result.add(Offset.lerp(p1, p2, t.clamp(0.0, 1.0))!);
    }
    return result;
  }

  StealGame({
    required this.config,
    required this.deviceService,
    AudioReactor? audioReactor,
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

    // Fill buffer with current smoothed position so trails don't start at (0.5, 0.5)
    final startPos = smoothedLogoPos;
    for (int i = 0; i < _trailBufferCapacity; i++) {
      _trailBuffer[i] = startPos;
    }
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
    _tickTrailBuffer();
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

  // -- Trail buffer -----------------------------------------------------------

  void _tickTrailBuffer() {
    // Keep buffer polling even if intensity is 0 so it's ready when toggled on

    // Sample interval: higher logoTrailLength = more frames between snapshots
    // = positions spread further apart = longer visible trail.
    // At 0.0 - every frame. At 2.0 - every ~30 frames.
    final interval = (1 + (config.logoTrailLength * 14.5).round()).clamp(1, 30);
    _trailFrameCount++;
    if (_trailFrameCount >= interval) {
      _trailFrameCount = 0;
      _trailHead = (_trailHead + 1) % _trailBufferCapacity;
      _trailBuffer[_trailHead] = smoothedLogoPos;
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
    final paletteColors = StealConfig.palettes[config.palette] ?? 
        (StealConfig.palettes.isNotEmpty ? StealConfig.palettes.values.first : [Colors.white]);
    _applyWoodstockColors(paletteColors, _woodstockFadeDuration * 2);
    _applyBannerConfig(config);
    _resetHoldTimer();
  }

  bool get isWoodstockActive => _woodstockPhase != _WoodstockPhase.idle;

  void updateConfig(StealConfig newConfig) {
    config = newConfig;
    _applyBannerConfig(newConfig);
    _applyGraphConfig(newConfig);
  }

  void _applyGraphConfig(StealConfig cfg) {
    if (_graph == null) return;
  }

  void _applyBannerConfig(StealConfig cfg) {
    if (_banner == null) return;
    final paletteColors = StealConfig.palettes[cfg.palette] ?? [Colors.white];
    final rawColor = paletteColors.isNotEmpty ? paletteColors.first : Colors.white;

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

  /// Unified beat pulse factor (0.0 to 1.0) with exponential decay.
  double get beatPulse => _beatPulse;

  /// Unified pulse scale multiplier combining base scale and audio energy.
  /// Used to synchronize logo and banner expansion.
  double get pulseScale {
    if (config.audioGraphMode == 'corner_only' ||
        !config.enableAudioReactivity) {
      return 1.0;
    }

    final energy = config.scaleSource == -1
        ? (_currentEnergy.bands.isEmpty ? 0.0 : _currentEnergy.bands[0])
        : _currentEnergy.bands[config.scaleSource.clamp(0, 7)];

    return (1.0 +
        energy * 0.2 * config.pulseIntensity * config.scaleMultiplier);
  }
}

enum _WoodstockPhase { idle, yellow, green }

