import 'package:just_audio/just_audio.dart';

/// A unified snapshot of audio engine diagnostics for HUD/telemetry.
class DngSnapshot {
  final Duration position;
  final Duration buffered;
  final Duration nextBuffered;
  final double drift;
  final String visibility;
  final PlayerState? playerState;
  final String? engineState;
  final String? engineContextState;
  final bool hbActive;
  final bool hbNeeded;
  final String? agentMessage;
  final String? notificationMessage;
  final String? lastIssueMessage;
  final DateTime? lastIssueAt;
  final String? error;
  final DateTime timestamp;

  DngSnapshot({
    required this.position,
    required this.buffered,
    required this.nextBuffered,
    required this.drift,
    required this.visibility,
    this.playerState,
    this.engineState,
    this.engineContextState,
    required this.hbActive,
    required this.hbNeeded,
    this.agentMessage,
    this.notificationMessage,
    this.lastIssueMessage,
    this.lastIssueAt,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'DngSnapshot(pos: $position, buf: $buffered, drift: $drift, error: $error)';
  }
}
