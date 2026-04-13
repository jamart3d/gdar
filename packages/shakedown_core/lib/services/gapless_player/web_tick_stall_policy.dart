class WebTickStallPolicy {
  static bool shouldResync({
    required bool playing,
    required bool visible,
    required DateTime? lastTickAt,
    required Duration stallThreshold,
    required DateTime now,
  }) {
    if (!playing || !visible || lastTickAt == null) {
      return false;
    }
    return now.difference(lastTickAt) >= stallThreshold;
  }

  static bool shouldInterpolate({
    required bool playing,
    required DateTime? lastTickAt,
    required Duration minGapBeforeInterpolate,
    required DateTime now,
  }) {
    if (!playing || lastTickAt == null) {
      return false;
    }
    return now.difference(lastTickAt) >= minGapBeforeInterpolate;
  }
}
