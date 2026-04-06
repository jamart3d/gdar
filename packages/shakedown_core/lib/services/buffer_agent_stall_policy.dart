class BufferAgentStallPolicy {
  static Duration stallThreshold({
    required bool isWeb,
    required bool isAppVisible,
  }) {
    return isWeb && isAppVisible
        ? const Duration(seconds: 10)
        : const Duration(seconds: 20);
  }
}
