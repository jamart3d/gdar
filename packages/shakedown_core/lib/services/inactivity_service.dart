import 'dart:async';
import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

/// Service to monitor user inactivity and trigger screensaver.
///
/// Uses a polling timer instead of a one-shot timer so the check can never
/// die permanently. Every [_pollInterval] seconds we compare wall-clock time
/// since the last activity against the configured duration.
class InactivityService {
  Timer? _pollTimer;
  final void Function() onInactivityTimeout;
  Duration _inactivityDuration;
  bool _isEnabled = false;
  DateTime _lastActivityAt = clock.now();
  bool _timeoutFiredSinceLastActivity = false;

  /// Observable countdown for on-screen debug overlay.
  /// Value is a human-readable status string (e.g. "42s", "OFF", "FIRED").
  final ValueNotifier<String> debugCountdown = ValueNotifier<String>('OFF');

  static const _pollInterval = Duration(seconds: 1);

  InactivityService({
    required this.onInactivityTimeout,
    required Duration initialDuration,
  }) : _inactivityDuration = initialDuration;

  void updateDuration(Duration duration) {
    if (_inactivityDuration == duration) return;
    _inactivityDuration = duration;
    debugPrint(
      'InactivityService: duration updated to ${_inactivityDuration.inMinutes}m',
    );
    // Reset activity so the new duration applies from now.
    if (_isEnabled) {
      _lastActivityAt = clock.now();
      _timeoutFiredSinceLastActivity = false;
    }
  }

  /// Whether the polling timer is running.
  bool get isTimerActive => _pollTimer?.isActive ?? false;

  /// Start monitoring for inactivity.
  void start() {
    if (_isEnabled && isTimerActive) return;
    _isEnabled = true;
    _lastActivityAt = clock.now();
    _timeoutFiredSinceLastActivity = false;
    debugPrint(
      'InactivityService: start (${_inactivityDuration.inMinutes}m timeout)',
    );
    _ensurePolling();
  }

  /// Stop monitoring for inactivity.
  void stop() {
    if (_isEnabled) {
      debugPrint('InactivityService: stop');
    }
    _isEnabled = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    debugCountdown.value = 'OFF';
  }

  /// Call this when user activity is detected.
  void onUserActivity([String source = 'activity']) {
    if (!_isEnabled) return;
    debugPrint('InactivityService: activity source=$source');
    _lastActivityAt = clock.now();
    _timeoutFiredSinceLastActivity = false;
    _ensurePolling();
  }

  void _ensurePolling() {
    if (_pollTimer?.isActive ?? false) return;
    _pollTimer = Timer.periodic(_pollInterval, _tick);
  }

  void _tick(Timer timer) {
    if (!_isEnabled) {
      timer.cancel();
      _pollTimer = null;
      debugCountdown.value = 'OFF';
      return;
    }

    final now = clock.now();
    final elapsed = now.difference(_lastActivityAt);
    final remaining = _inactivityDuration - elapsed;

    debugPrint(
      'InactivityService: tick elapsed=${elapsed.inSeconds}s, '
      'remaining=${remaining.inSeconds}s, '
      'timeoutFired=$_timeoutFiredSinceLastActivity',
    );

    if (remaining <= Duration.zero) {
      if (!_timeoutFiredSinceLastActivity) {
        _timeoutFiredSinceLastActivity = true;
        debugCountdown.value = 'FIRED';
        debugPrint(
          'InactivityService: timeout fired — launching screensaver'
          ' (elapsed=${elapsed.inSeconds}s,'
          ' target=${_inactivityDuration.inSeconds}s)',
        );
        onInactivityTimeout();
      } else {
        // Already fired, waiting for activity or stop to reset.
        debugCountdown.value = 'WAIT';
      }
    } else {
      debugCountdown.value = '${remaining.inSeconds}s';
    }
  }

  void dispose() {
    stop();
    debugCountdown.dispose();
  }
}

/// Widget that wraps the app to detect user activity.
class InactivityDetector extends StatefulWidget {
  final Widget child;
  final InactivityService? inactivityService;
  final bool isScreensaverActive;

  const InactivityDetector({
    super.key,
    required this.child,
    this.inactivityService,
    this.isScreensaverActive = false,
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
    if (event is KeyDownEvent && event is! KeyRepeatEvent) {
      if (!widget.isScreensaverActive) {
        final key = event.logicalKey;

        final isDirectional =
            key == LogicalKeyboardKey.arrowUp ||
            key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.arrowLeft ||
            key == LogicalKeyboardKey.arrowRight;

        final isSelection =
            key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.space;

        final isNavigation =
            key == LogicalKeyboardKey.goBack ||
            key == LogicalKeyboardKey.escape ||
            key == LogicalKeyboardKey.backspace;

        final isMedia =
            key.debugName != null && key.debugName!.contains('Media');

        if (isDirectional || isSelection || isNavigation || isMedia) {
          widget.inactivityService?.onUserActivity('key:${key.keyLabel}');
        }
      }
    }
    return false; // Let the event propagate
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      // For TV we care about intentional activity, not hover/noise. Pointer
      // move churn on real hardware can keep the timer alive forever.
      onPointerDown: (_) => widget.isScreensaverActive
          ? null
          : widget.inactivityService?.onUserActivity('pointerDown'),
      child: widget.child,
    );
  }
}
