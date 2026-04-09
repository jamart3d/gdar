import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

bool shouldDeferMicrophonePermission({
  required TargetPlatform targetPlatform,
  required bool isTv,
  required String beatDetectorMode,
}) {
  if (targetPlatform != TargetPlatform.android) {
    return false;
  }
  return isTv && beatDetectorMode == 'pcm';
}

class MicrophonePermissionFlow {
  MicrophonePermissionFlow({
    Future<PermissionStatus> Function()? statusReader,
    Future<PermissionStatus> Function()? requestPermission,
    this.cooldownDuration = const Duration(milliseconds: 600),
  }) : _statusReader = statusReader ?? _defaultStatusReader,
       _requestPermission = requestPermission ?? _defaultRequestPermission;

  final Future<PermissionStatus> Function() _statusReader;
  final Future<PermissionStatus> Function() _requestPermission;
  final Duration cooldownDuration;

  bool _isPermissionFlowActive = false;
  bool _isPermissionFlowCooldown = false;
  Timer? _permissionFlowCooldownTimer;

  bool get isPermissionFlowActive => _isPermissionFlowActive;
  bool get isPermissionFlowCooldown => _isPermissionFlowCooldown;

  Future<PermissionStatus?> getMicrophonePermissionStatus() async {
    try {
      return await _statusReader();
    } catch (error) {
      debugPrint(
        'Screensaver: Failed to read microphone permission status: $error',
      );
      return null;
    }
  }

  Future<PermissionStatus?> requestMicrophonePermission() async {
    try {
      return await runPermissionFlow(_requestPermission);
    } catch (error) {
      debugPrint(
        'Screensaver: Failed to request microphone permission: $error',
      );
      return null;
    }
  }

  Future<T> runPermissionFlow<T>(Future<T> Function() action) async {
    _isPermissionFlowActive = true;
    try {
      return await action();
    } finally {
      _isPermissionFlowActive = false;
      _isPermissionFlowCooldown = true;
      _permissionFlowCooldownTimer?.cancel();
      _permissionFlowCooldownTimer = Timer(
        cooldownDuration,
        () => _isPermissionFlowCooldown = false,
      );
    }
  }

  void dispose() {
    _permissionFlowCooldownTimer?.cancel();
  }

  static Future<PermissionStatus> _defaultStatusReader() {
    return Permission.microphone.status;
  }

  static Future<PermissionStatus> _defaultRequestPermission() {
    return Permission.microphone.request();
  }
}
