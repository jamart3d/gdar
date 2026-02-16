import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/utils/logger.dart';

/// Service to monitor user inactivity and trigger screensaver.
///
/// This service listens to pointer events (mouse/touch) and key events
/// to detect user activity. When the configured inactivity timeout is
/// reached, it triggers a callback to launch the screensaver.
class InactivityService {
  Timer? _inactivityTimer;
  final void Function() onInactivityTimeout;
  Duration _inactivityDuration;
  bool _isEnabled = false;

  InactivityService({
    required this.onInactivityTimeout,
    required Duration initialDuration,
  }) : _inactivityDuration = initialDuration;

  void updateDuration(Duration duration) {
    if (_inactivityDuration == duration) return;
    _inactivityDuration = duration;
    if (_isEnabled) {
      _resetTimer();
    }
    logger.d(
        'InactivityService: Updated duration to ${_inactivityDuration.inMinutes} min');
  }

  /// Start monitoring for inactivity.
  void start() {
    if (_isEnabled) return;
    _isEnabled = true;
    _resetTimer();
    logger.i(
        'InactivityService: Started monitoring (timeout: ${_inactivityDuration.inMinutes} min)');
  }

  /// Stop monitoring for inactivity.
  void stop() {
    _isEnabled = false;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    logger.i('InactivityService: Stopped monitoring');
  }

  /// Call this when user activity is detected.
  void onUserActivity() {
    if (!_isEnabled) return;
    _resetTimer();
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      logger.i(
          'InactivityService: Inactivity timeout reached, triggering screensaver');
      onInactivityTimeout();
    });
  }

  void dispose() {
    stop();
  }
}

/// Widget that wraps the app to detect user activity.
class InactivityDetector extends StatefulWidget {
  final Widget child;
  final InactivityService? inactivityService;

  const InactivityDetector({
    super.key,
    required this.child,
    this.inactivityService,
  });

  @override
  State<InactivityDetector> createState() => _InactivityDetectorState();
}

class _InactivityDetectorState extends State<InactivityDetector> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    // We only care about key down events to avoid double triggering
    if (event is KeyDownEvent) {
      widget.inactivityService?.onUserActivity();
    }
    return false; // Let the event propagate
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => widget.inactivityService?.onUserActivity(),
      onPointerMove: (_) => widget.inactivityService?.onUserActivity(),
      onPointerUp: (_) => widget.inactivityService?.onUserActivity(),
      child: widget.child,
    );
  }
}
