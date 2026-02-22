import 'dart:async';
import 'dart:math';
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

  AudioReactor? _audioReactor;
  StreamSubscription<AudioEnergy>? _energySubscription;
  StealBackground? _background;
  StealBanner? _banner;
  double _time = 0;
  AudioEnergy _currentEnergy = const AudioEnergy.zero();

  // ── Palette Cycling ────────────────────────────────────────────────────────
  static const double _baseFadeDuration = 3.0;
  static const double _baseHoldMin = 20.0;
  static const double _baseHoldMax = 40.0;
  static const double _holdVariance = 0.3;

  final _rng = Random();
  double _cycleTimer = 0.0;
  double _holdDuration = 0.0;
  bool _cycling = false;
  String _lastPalette = '';

  // ── Trail position ring buffer ─────────────────────────────────────────────
  // Stores recent smoothed logo positions for ghost slice rendering.
  // Max capacity = max supported slices. Sampled every N frames based on
  // logoTrailLength (higher = more frames skipped = longer spread trail).
  static const int _trailBufferCapacity = 16;
  final List<Offset> _trailBuffer = List.filled(
    _trailBufferCapacity,
    const Offset(0.5, 0.5),
  );
  int _trailHead = 0;
  int _trailFrameCount = 0;

  /// Returns up to [count] trail positions, newest first.
  List<Offset> getTrailPositions(int count) {
    final clamped = count.clamp(0, _trailBufferCapacity);
    final result = <Offset>[];
    for (int i = 0; i < clamped; i++) {
      final idx =
          ((_trailHead - i) % _trailBufferCapacity + _trailBufferCapacity) %
              _trailBufferCapacity;
      result.add(_trailBuffer[idx]);
    }
    return result;
  }

  StealGame({
    required this.config,
    AudioReactor? audioReactor,
    required this.deviceService,
  }) : _audioReactor = audioReactor;

  @override
  Color backgroundColor() => const Color(0xFF000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _subscribeToReactor(_audioReactor);

    _background = StealBackground(config: config);
    add(_background!);

    _banner = StealBanner();
    add(_banner!);

    _applyBannerConfig(config);

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

    if (config.paletteCycle && !isWoodstockActive) {
      _tickCycle(dt);
    }

    _tickWoodstock(dt);
    _tickTrailBuffer();
  }

  // ── Trail buffer ───────────────────────────────────────────────────────────

  void _tickTrailBuffer() {
    if (config.logoTrailIntensity <= 0.0) return;

    // Sample interval: higher logoTrailLength = more frames between snapshots
    // = positions spread further apart = longer visible trail.
    // At 0.0 → every frame. At 1.0 → every 12 frames.
    final interval = (1 + (config.logoTrailLength * 11).round()).clamp(1, 12);
    _trailFrameCount++;
    if (_trailFrameCount >= interval) {
      _trailFrameCount = 0;
      _trailHead = (_trailHead + 1) % _trailBufferCapacity;
      _trailBuffer[_trailHead] = smoothedLogoPos;
    }
  }

  // ── Cycle logic ────────────────────────────────────────────────────────────

  double get _speed => config.paletteTransitionSpeed.clamp(0.1, 20.0);
  double get _scaledHoldMin => _baseHoldMin / _speed;
  double get _scaledHoldMax => _baseHoldMax / _speed;
  double get _scaledFadeDuration => _baseFadeDuration / _speed;

  void _resetHoldTimer() {
    final range = _scaledHoldMax - _scaledHoldMin;
    final variance = range * _holdVariance;
    final base = _scaledHoldMin + _rng.nextDouble() * range;
    _holdDuration = (base + (_rng.nextDouble() * 2 - 1) * variance)
        .clamp(_scaledHoldMin * 0.5, _scaledHoldMax * 2.0);
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

    final lerpSpeed = _lerpSpeedFromFadeDuration(_scaledFadeDuration);
    _background?.updateConfigWithLerpSpeed(newConfig, lerpSpeed);
    _applyBannerConfig(newConfig);

    _resetHoldTimer();
  }

  double _lerpSpeedFromFadeDuration(double durationSeconds) {
    final clamped = durationSeconds.clamp(0.1, 60.0);
    return (1.0 - exp(-1.0 / (clamped * 60.0))).clamp(0.001, 1.0);
  }

  // ── Woodstock Mode ─────────────────────────────────────────────────────────
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
    final lerpSpeed = _lerpSpeedFromFadeDuration(fadeDuration);
    _background?.overrideTargetColors(colors, lerpSpeed);
    _banner?.updateBanner(
      config.bannerText,
      colors.first,
      showBanner: config.showInfoBanner,
      venue: config.venue,
      date: config.date,
    );
  }

  void _restoreNormalPalette() {
    final paletteColors = StealConfig.palettes[config.palette] ??
        StealConfig.palettes.values.first;
    final lerpSpeed = _lerpSpeedFromFadeDuration(_woodstockFadeDuration * 2);
    _background?.overrideTargetColors(paletteColors, lerpSpeed);
    _applyBannerConfig(config);
    _resetHoldTimer();
  }

  bool get isWoodstockActive => _woodstockPhase != _WoodstockPhase.idle;

  void updateConfig(StealConfig newConfig) {
    config = newConfig;
    _background?.updateConfig(newConfig);
    _applyBannerConfig(newConfig);
  }

  void _applyBannerConfig(StealConfig cfg) {
    if (_banner == null) return;
    final paletteColors =
        StealConfig.palettes[cfg.palette] ?? StealConfig.palettes.values.first;
    final rawColor =
        paletteColors.isNotEmpty ? paletteColors.first : Colors.white;

    final bannerColor =
        rawColor.computeLuminance() > 0.85 ? const Color(0xFFFFD700) : rawColor;

    _banner!.updateBanner(
      cfg.bannerText,
      bannerColor,
      showBanner: cfg.showInfoBanner,
      venue: cfg.venue,
      date: cfg.date,
    );
  }

  @override
  void onRemove() {
    _energySubscription?.cancel();
    super.onRemove();
  }

  double get time => _time;
  AudioEnergy get currentEnergy => _currentEnergy;

  /// Smoothed logo position in 0–1 UV space, driven by StealBackground.
  /// Used by StealBanner to keep rings locked to the logo center.
  Offset get smoothedLogoPos =>
      _background?.smoothedLogoPos ?? const Offset(0.5, 0.5);
}

enum _WoodstockPhase { idle, yellow, green }
