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
  final double? fetchTtfbMs;
  final bool fetchInFlight;
  final double? lastGapMs;

  // New telemetry
  final int? scheduledIndex;
  final double? scheduledStartContextTime;
  final double? ctxCurrentTime;
  final double? outputLatencyMs;
  final double? lastDecodeMs;
  final double? lastConcatMs;
  final int? failedTrackCount;
  final int? workerTickCount;
  final int? sampleRate;
  final int? decodedCacheSize;
  final String? handoffState;
  final int? handoffAttemptCount;
  final int? lastHandoffPollCount;

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
    this.fetchTtfbMs,
    this.fetchInFlight = false,
    this.lastGapMs,
    this.scheduledIndex,
    this.scheduledStartContextTime,
    this.ctxCurrentTime,
    this.outputLatencyMs,
    this.lastDecodeMs,
    this.lastConcatMs,
    this.failedTrackCount,
    this.workerTickCount,
    this.sampleRate,
    this.decodedCacheSize,
    this.handoffState,
    this.handoffAttemptCount,
    this.lastHandoffPollCount,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'DngSnapshot(pos: $position, buf: $buffered, drift: $drift, error: $error)';
  }
}
