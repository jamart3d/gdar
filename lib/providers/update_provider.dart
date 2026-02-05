import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shakedown/services/update_service.dart';
import 'package:shakedown/utils/logger.dart';

/// Provider to manage the app update state and lifecycle.
class UpdateProvider with ChangeNotifier {
  final UpdateService _updateService = UpdateService();

  AppUpdateInfo? _updateInfo;
  bool _isSimulated = false;

  /// Current update information from the Play Store or simulation.
  AppUpdateInfo? get updateInfo => _updateInfo;

  /// Whether the current update state is simulated for testing.
  bool get isSimulated => _isSimulated;

  UpdateProvider() {
    // Auto-check on cold start
    if (!kDebugMode) {
      checkForUpdate();
    }
  }

  /// Checks for available updates on the Play Store.
  Future<void> checkForUpdate() async {
    if (_isSimulated) return;

    // Safety check for debug mode unless specifically asked (simulateUpdate handles debug)
    if (kDebugMode && !_isSimulated) {
      logger
          .d('UpdateProvider: Skipping automatic update check in Debug mode.');
      return;
    }

    final info = await _updateService.checkForUpdate();
    _updateInfo = info;

    if (info?.updateAvailability == UpdateAvailability.updateAvailable) {
      logger.i(
          'UpdateProvider: New update available: ${info?.availableVersionCode}');
    }

    notifyListeners();
  }

  /// Redirects the user to the Play Store for the update.
  Future<void> startUpdate() async {
    if (_isSimulated) {
      logger.i('UpdateProvider: Simulating store redirect.');
      await _updateService.openStore();
      return;
    }

    if (_updateInfo == null) return;
    await _updateService.openStore();
  }

  /// Simulates an available update for debug/testing purposes.
  void simulateUpdate() {
    _isSimulated = true;
    _updateInfo = null;
    notifyListeners();
  }
}
