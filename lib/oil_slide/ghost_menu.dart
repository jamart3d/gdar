import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/oil_slide/oil_slide_config.dart';
import 'package:shakedown/oil_slide/kiosk_exit_detector.dart';
import 'package:shakedown/oil_slide/easter_egg_detector.dart';
import 'dart:ui';

/// Ghost Menu overlay for oil_slide screensaver.
///
/// Provides a glassmorphism-styled UI for adjusting parameters in real-time.
/// - Appears on D-Pad input
/// - Auto-hides after 5 seconds of inactivity
/// - Supports D-Pad navigation and adjustment
/// - Detects easter eggs (Konami code, Woodstock mode)
class GhostMenu extends StatefulWidget {
  final OilSlideConfig config;
  final ValueChanged<OilSlideConfig> onConfigChanged;
  final VoidCallback? onExit;
  final bool kioskMode;
  final bool enableEasterEggs;
  final void Function(EasterEgg)? onEasterEgg;

  const GhostMenu({
    super.key,
    required this.config,
    required this.onConfigChanged,
    this.onExit,
    this.kioskMode = false,
    this.enableEasterEggs = true,
    this.onEasterEgg,
  });

  @override
  State<GhostMenu> createState() => _GhostMenuState();
}

class _GhostMenuState extends State<GhostMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _hideTimer;
  int _selectedIndex = 0;
  bool _isVisible = false;
  KioskExitDetector? _kioskExitDetector;
  EasterEggDetector? _easterEggDetector;

  // Menu items with their current values and adjustment logic
  final List<_MenuItem> _menuItems = [];

  @override
  void initState() {
    super.initState();

    // Initialize kiosk exit detector if in kiosk mode
    if (widget.kioskMode) {
      _kioskExitDetector = KioskExitDetector();
    }

    // Initialize easter egg detector if enabled
    if (widget.enableEasterEggs) {
      _easterEggDetector = EasterEggDetector(
        onEasterEggTriggered: (egg) {
          widget.onEasterEgg?.call(egg);
        },
      );
    }

    // Initialize menu items
    _initializeMenuItems();

    // Setup animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  void _initializeMenuItems() {
    _menuItems.addAll([
      _MenuItem(
        label: 'Visual Mode',
        getValue: _getVisualModeValue,
        setValue: (value) {
          _setVisualMode(value);
          // Return valid config because _setVisualMode handles the actual update
          // but _MenuItem expects a return. We can return current config or
          // the one updated by _setVisualMode if we refactored.
          // However, _setVisualMode calls onConfigChanged directly.
          // To satisfy the signature, we can return the CURRENT config,
          // relying on the side effect of _setVisualMode.
          return widget.config;
        },
        min: 0.0,
        max: 3.0,
        step: 1.0,
        isInteger: true,
      ),
      _MenuItem(
        label: 'Viscosity',
        getValue: () => widget.config.viscosity,
        setValue: (value) => widget.config.copyWith(
            viscosity: value, visualMode: 'custom'), // Switch to custom
        min: 0.0,
        max: 1.0,
        step: 0.05,
      ),
      _MenuItem(
        label: 'Flow Speed',
        getValue: () => widget.config.flowSpeed,
        setValue: (value) =>
            widget.config.copyWith(flowSpeed: value, visualMode: 'custom'),
        min: 0.0,
        max: 2.0,
        step: 0.1,
      ),
      _MenuItem(
        label: 'Pulse Intensity',
        getValue: () => widget.config.pulseIntensity,
        setValue: (value) =>
            widget.config.copyWith(pulseIntensity: value, visualMode: 'custom'),
        min: 0.0,
        max: 1.0,
        step: 0.05,
      ),
      _MenuItem(
        label: 'Film Grain',
        getValue: () => widget.config.filmGrain,
        setValue: (value) =>
            widget.config.copyWith(filmGrain: value, visualMode: 'custom'),
        min: 0.0,
        max: 1.0,
        step: 0.05,
      ),
      _MenuItem(
        label: 'Heat Drift',
        getValue: () => widget.config.heatDrift,
        setValue: (value) =>
            widget.config.copyWith(heatDrift: value, visualMode: 'custom'),
        min: 0.0,
        max: 1.0,
        step: 0.05,
      ),
      _MenuItem(
        label: 'Metaball Count',
        getValue: () => widget.config.metaballCount.toDouble(),
        setValue: (value) => widget.config
            .copyWith(metaballCount: value.round(), visualMode: 'custom'),
        min: 4.0,
        max: 10.0,
        step: 1.0,
        isInteger: true,
      ),
    ]);
  }

  double _getVisualModeValue() {
    switch (widget.config.visualMode) {
      case 'lava_lamp':
        return 0.0;
      case 'silk':
        return 1.0;
      case 'psychedelic':
        return 2.0;
      default: // custom
        return 3.0;
    }
  }

  void _setVisualMode(double value) {
    String mode;
    int index = value.round();
    if (index == 0) {
      mode = 'lava_lamp';
    } else if (index == 1) {
      mode = 'silk';
    } else if (index == 2) {
      mode = 'psychedelic';
    } else {
      mode = 'custom';
    }

    if (mode != 'custom') {
      widget.onConfigChanged(OilSlideConfig.fromMode(mode));
    } else {
      widget.onConfigChanged(widget.config.copyWith(visualMode: 'custom'));
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _kioskExitDetector?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _show() {
    if (!_isVisible) {
      setState(() => _isVisible = true);
      _animationController.forward();
    }
    _resetHideTimer();
  }

  void _hide() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() => _isVisible = false);
      }
    });
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), _hide);
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // Pass to easter egg detector first
    _easterEggDetector?.handleKeyEvent(event);

    // Show menu on any key if hidden
    if (!_isVisible) {
      _show();
      return;
    }

    // Reset hide timer on any interaction
    _resetHideTimer();

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.gameButtonA: // Some remotes map up to A
        setState(() {
          _selectedIndex = (_selectedIndex - 1) % _menuItems.length;
          if (_selectedIndex < 0) _selectedIndex = _menuItems.length - 1;
        });
        break;

      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.gameButtonB: // Some remotes map down to B
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _menuItems.length;
        });
        break;

      case LogicalKeyboardKey.arrowLeft:
        _adjustValue(-1);
        break;

      case LogicalKeyboardKey.arrowRight:
        _adjustValue(1);
        break;

      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
        // Toggle menu visibility
        if (_isVisible) {
          _hide();
        }
        break;

      case LogicalKeyboardKey.escape:
      case LogicalKeyboardKey.goBack:
        // Handle exit based on kiosk mode
        if (widget.kioskMode && _kioskExitDetector != null) {
          // In kiosk mode, require double-back press
          if (_kioskExitDetector!.shouldExit()) {
            widget.onExit?.call();
          }
          // First press doesn't exit, just registers the press
        } else {
          // Not in kiosk mode, exit immediately
          widget.onExit?.call();
        }
        break;
    }
  }

  void _adjustValue(int direction) {
    final item = _menuItems[_selectedIndex];
    final currentValue = item.getValue();
    final newValue =
        (currentValue + (item.step * direction)).clamp(item.min, item.max);

    final newConfig = item.setValue(newValue);
    widget.onConfigChanged(newConfig);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          if (!_isVisible && _fadeAnimation.value == 0) {
            return const SizedBox.shrink();
          }

          return Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          );
        },
        child: _buildMenuOverlay(),
      ),
    );
  }

  Widget _buildMenuOverlay() {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'oil_slide',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Menu items
                  for (int i = 0; i < _menuItems.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: _buildMenuItem(
                        _menuItems[i].label,
                        _menuItems[i].getValue(),
                        _menuItems[i].min,
                        _menuItems[i].max,
                        isSelected: i == _selectedIndex,
                        isInteger: _menuItems[i].isInteger,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Footer hint
                  Text(
                    '← → Adjust  •  ↑ ↓ Navigate  •  ESC Exit',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    String label,
    double value,
    double min,
    double max, {
    required bool isSelected,
    bool isInteger = false,
  }) {
    String displayValue;
    if (label == 'Visual Mode') {
      int modeIndex = value.round();
      switch (modeIndex) {
        case 0:
          displayValue = 'Lava Lamp';
          break;
        case 1:
          displayValue = 'Silk';
          break;
        case 2:
          displayValue = 'Psychedelic';
          break;
        default:
          displayValue = 'Custom';
      }
    } else {
      displayValue =
          isInteger ? value.round().toString() : value.toStringAsFixed(2);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.8),
                ),
              ),
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value - min) / (max - min),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                Colors.white.withValues(alpha: isSelected ? 0.8 : 0.5),
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Internal class representing a menu item
class _MenuItem {
  final String label;
  final double Function() getValue;
  final OilSlideConfig Function(double) setValue;
  final double min;
  final double max;
  final double step;
  final bool isInteger;

  _MenuItem({
    required this.label,
    required this.getValue,
    required this.setValue,
    required this.min,
    required this.max,
    required this.step,
    this.isInteger = false,
  });
}
