import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

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
  DateTime? _lastActivityLogAt;

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
    if (_isEnabled) {
      _resetTimer();
    }
  }

  /// Start monitoring for inactivity.
  void start() {
    if (_isEnabled) return;
    _isEnabled = true;
    debugPrint(
      'InactivityService: start (${_inactivityDuration.inMinutes}m timeout)',
    );
    _resetTimer();
  }

  /// Stop monitoring for inactivity.
  void stop() {
    if (_isEnabled) {
      debugPrint('InactivityService: stop');
    }
    _isEnabled = false;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  /// Call this when user activity is detected.
  void onUserActivity([String source = 'activity']) {
    if (!_isEnabled) return;
    final now = DateTime.now();
    if (_lastActivityLogAt == null ||
        now.difference(_lastActivityLogAt!) >= const Duration(seconds: 1)) {
      _lastActivityLogAt = now;
      debugPrint('InactivityService: activity from $source; resetting timer');
    }
    _resetTimer();
  }

  void _resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      debugPrint('InactivityService: timeout fired');
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
    if (event is KeyDownEvent) {
      if (!widget.isScreensaverActive) {
        widget.inactivityService?.onUserActivity(
          'key:${event.logicalKey.keyLabel}',
        );
      }
    }
    return false; // Let the event propagate
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => widget.isScreensaverActive
          ? null
          : widget.inactivityService?.onUserActivity('pointerDown'),
      onPointerMove: (_) => widget.isScreensaverActive
          ? null
          : widget.inactivityService?.onUserActivity('pointerMove'),
      onPointerUp: (_) => widget.isScreensaverActive
          ? null
          : widget.inactivityService?.onUserActivity('pointerUp'),
      child: widget.child,
    );
  }
}
