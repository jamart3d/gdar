import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shakedown_core/ui/screens/screensaver/microphone_permission_flow.dart';

void main() {
  group('MicrophonePermissionFlow', () {
    test('defers microphone permission only for Android TV pcm mode', () {
      expect(
        shouldDeferMicrophonePermission(
          targetPlatform: TargetPlatform.android,
          isTv: true,
          beatDetectorMode: 'pcm',
        ),
        isTrue,
      );
      expect(
        shouldDeferMicrophonePermission(
          targetPlatform: TargetPlatform.android,
          isTv: true,
          beatDetectorMode: 'fft',
        ),
        isFalse,
      );
      expect(
        shouldDeferMicrophonePermission(
          targetPlatform: TargetPlatform.iOS,
          isTv: true,
          beatDetectorMode: 'pcm',
        ),
        isFalse,
      );
      expect(
        shouldDeferMicrophonePermission(
          targetPlatform: TargetPlatform.android,
          isTv: false,
          beatDetectorMode: 'pcm',
        ),
        isFalse,
      );
    });

    test('returns null when reading microphone status throws', () async {
      final flow = MicrophonePermissionFlow(
        statusReader: () async => throw Exception('boom'),
        requestPermission: () async => PermissionStatus.granted,
        cooldownDuration: Duration.zero,
      );

      expect(await flow.getMicrophonePermissionStatus(), isNull);
    });

    test('wraps permission requests with active and cooldown guards', () async {
      final completer = Completer<PermissionStatus>();
      final flow = MicrophonePermissionFlow(
        statusReader: () async => PermissionStatus.denied,
        requestPermission: () => completer.future,
        cooldownDuration: const Duration(milliseconds: 1),
      );

      final requestFuture = flow.requestMicrophonePermission();
      expect(flow.isPermissionFlowActive, isTrue);
      expect(flow.isPermissionFlowCooldown, isFalse);

      completer.complete(PermissionStatus.granted);
      expect(await requestFuture, PermissionStatus.granted);
      expect(flow.isPermissionFlowActive, isFalse);
      expect(flow.isPermissionFlowCooldown, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(flow.isPermissionFlowCooldown, isFalse);
      flow.dispose();
    });
  });
}
