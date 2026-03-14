class GdarHudSnapshot {
  final String engine;
  final String contextState;
  final bool survival;
  final String url;
  final double mdft;
  final int rvc;
  final String vDur;
  final int timestamp;
  final Map<String, dynamic> metadata;

  const GdarHudSnapshot({
    required this.engine,
    required this.contextState,
    required this.survival,
    required this.url,
    required this.mdft,
    required this.rvc,
    required this.vDur,
    required this.timestamp,
    this.metadata = const {},
  });

  GdarHudSnapshot copyWith({
    String? engine,
    String? contextState,
    bool? survival,
    String? url,
    double? mdft,
    int? rvc,
    String? vDur,
    int? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return GdarHudSnapshot(
      engine: engine ?? this.engine,
      contextState: contextState ?? this.contextState,
      survival: survival ?? this.survival,
      url: url ?? this.url,
      mdft: mdft ?? this.mdft,
      rvc: rvc ?? this.rvc,
      vDur: vDur ?? this.vDur,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }
}

abstract class GdarAudioInterface {
  /// Stream providing real-time telemetry from the audio engine.
  Stream<GdarHudSnapshot> get telemetryStream;

  /// Initializes the audio engine.
  Future<void> initialize();

  /// Starts playback of the given [url].
  /// [volume] defaults to 1.0 if not specified.
  Future<void> play(String url, {double volume});

  /// Enables or disables 'Survival Mode' for background heartbeats.
  void setSurvivalMode(bool active);

  /// Notifies the engine of changes in app visibility.
  void updateVisibility(bool isVisible);
}
