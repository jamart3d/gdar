Map<String, dynamic> buildPassVerificationStatus({
  required String sha,
  required DateTime timestamp,
}) {
  return {
    'last_verification_commit': sha,
    'status': 'PASS',
    'score': 100,
    'results': {
      'analyze': 'SUCCESS',
      'test': 'SUCCESS (All tests passed)',
      'format': 'SUCCESS (Clean workspace)',
    },
    'timestamp': timestamp.toIso8601String(),
  };
}

Map<String, dynamic> buildSavedVerificationStatus({
  required String sha,
  required DateTime timestamp,
}) {
  const staleMessage = 'STALE (New commit saved without fresh verification)';

  return {
    'last_verification_commit': sha,
    'status': 'SAVED',
    'score': 0,
    'results': {
      'analyze': staleMessage,
      'test': staleMessage,
      'format': staleMessage,
    },
    'timestamp': timestamp.toIso8601String(),
  };
}
