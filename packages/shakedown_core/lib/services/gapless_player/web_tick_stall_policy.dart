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
}
