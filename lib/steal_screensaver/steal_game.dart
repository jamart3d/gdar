import 'dart:async';
import 'dart:math';
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
  static const double _baseFadeDuration =
      3.0; // seconds for crossfade at speed 1.0
  static const double _baseHoldMin = 20.0; // min hold seconds at speed 1.0
  static const double _baseHoldMax = 40.0; // max hold seconds at speed 1.0
  static const double _holdVariance = 0.3; // ±30% random variation on hold

  final _rng = Random();
  double _cycleTimer = 0.0; // counts up during hold
  double _holdDuration = 0.0; // current randomised hold target
  bool _cycling = false;
  String _lastPalette = '';

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

    // Seed cycle state so first hold is randomised from the start
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
  }

  // ── Cycle logic ─────────────────────────────────────────────────────────

  /// speed > 1 = faster; speed < 1 = slower.
  /// At the default of 5.0: hold ~4–8s, fade ~0.6s — smooth but lively.
  /// At 1.0: hold ~20–40s, fade ~3s — slow and meditative.
  double get _speed => config.paletteTransitionSpeed.clamp(0.1, 20.0);

  double get _scaledHoldMin => _baseHoldMin / _speed;
  double get _scaledHoldMax => _baseHoldMax / _speed;
  double get _scaledFadeDuration => _baseFadeDuration / _speed;

  void _resetHoldTimer() {
    final range = _scaledHoldMax - _scaledHoldMin;
    final variance = range * _holdVariance;
    final base = _scaledHoldMin + _rng.nextDouble() * range;
    // Add ±variance wobble
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

    // Pick a random palette that isn't the current one
    String next;
    if (keys.length <= 1) {
      next = keys.first;
    } else {
      final candidates = keys.where((k) => k != _lastPalette).toList();
      next = candidates[_rng.nextInt(candidates.length)];
    }

    _lastPalette = next;

    // Update config so banner color also transitions
    final newConfig = config.copyWith(palette: next);
    config = newConfig;

    // Drive StealBackground crossfade speed from transitionSpeed
    final lerpSpeed = _lerpSpeedFromFadeDuration(_scaledFadeDuration);
    _background?.updateConfigWithLerpSpeed(newConfig, lerpSpeed);
    _applyBannerConfig(newConfig);

    // Reset hold timer for next cycle
    _resetHoldTimer();
  }

  /// Converts a desired fade duration (seconds) to a per-frame lerp factor.
  /// lerp factor ≈ 1 - e^(-dt/duration) — approximated for 60fps as:
  ///   factor = 1 - exp(-1 / (duration * 60))
  double _lerpSpeedFromFadeDuration(double durationSeconds) {
    final clamped = durationSeconds.clamp(0.1, 60.0);
    return (1.0 - exp(-1.0 / (clamped * 60.0))).clamp(0.001, 1.0);
  }

  // ── Woodstock Mode (4:20 Easter Egg) ──────────────────────────────────────
  static const double _woodstockYellowDuration = 15.0; // seconds
  static const double _woodstockGreenDuration = 4 * 60 + 20.0; // 4m20s
  static const double _woodstockFadeDuration = 5.0; // crossfade seconds
  static const Color _woodstockYellow = Color(0xFFFFD700);
  static const Color _woodstockGreen = Color(0xFF00CC44);

  // Phases: idle → yellow → green → restore
  _WoodstockPhase _woodstockPhase = _WoodstockPhase.idle;
  double _woodstockTimer = 0.0;

  /// Called by StealVisualizer when EasterEggDetector fires.
  /// Safe to call multiple times — ignored if already active.
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
          // Restore normal palette — use slower fade back for elegance
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
    // Banner color follows woodstock — pick first color directly, skip luminance check
    _banner?.updateBanner(
      config.bannerText,
      colors.first,
      showBanner: config.showInfoBanner,
    );
  }

  void _restoreNormalPalette() {
    final paletteColors = StealConfig.palettes[config.palette] ??
        StealConfig.palettes.values.first;
    final lerpSpeed = _lerpSpeedFromFadeDuration(_woodstockFadeDuration * 2);
    _background?.overrideTargetColors(paletteColors, lerpSpeed);
    _applyBannerConfig(config);
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

    // For near-white palettes the text would be invisible against the bright
    // shader. Use the cycling palette color from the shader instead — it's
    // always visible because it's tinted against black. As a simple heuristic:
    // if the color's luminance is > 0.7, fall back to a gold/amber that reads
    // clearly over any shader background.
    final bannerColor = rawColor.computeLuminance() > 0.7
        ? const Color(0xFFFFD700) // gold — readable on dark AND bright areas
        : rawColor;

    _banner!.updateBanner(
      cfg.bannerText,
      bannerColor,
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

enum _WoodstockPhase { idle, yellow, green }
