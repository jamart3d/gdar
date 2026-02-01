import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown/services/update_service.dart';
import 'package:shakedown/utils/logger.dart';

/// Provider to manage the app update state and lifecycle.
class UpdateProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final UpdateService _updateService = UpdateService();

  AppUpdateInfo? _updateInfo;
  bool _isDownloading = false;
  bool _isSimulated = false;

  static const String _kUpdateDownloadedKey = 'update_downloaded';

  /// Current update information from the Play Store or simulation.
  AppUpdateInfo? get updateInfo => _updateInfo;

  /// Whether a flexible update is currently being downloaded or ready to install.
  bool get isDownloading => _isDownloading;

  /// Whether the current update state is simulated for testing.
  bool get isSimulated => _isSimulated;

  UpdateProvider(this._prefs) {
    _loadPersistedState();
    // Auto-check on cold start
    if (!kDebugMode) {
      checkForUpdate();
    }
  }

  void _loadPersistedState() {
    _isDownloading = _prefs.getBool(_kUpdateDownloadedKey) ?? false;
    if (_isDownloading) {
      logger.i(
          'UpdateProvider: Restored "Update Downloaded" state from persistence.');
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

    // If we were in "downloading" state but the check says no update or different status,
    // we might need to reset. But for now, we trust the persistence for the "Ready to Install" banner.
    if (info?.updateAvailability == UpdateAvailability.updateAvailable) {
      logger.i(
          'UpdateProvider: New update available: ${info?.availableVersionCode}');
    }

    notifyListeners();
  }

  /// Starts the flexible update process.
  Future<void> startUpdate() async {
    if (_isSimulated) {
      _isDownloading = true;
      _prefs.setBool(_kUpdateDownloadedKey, true);
      notifyListeners();
      return;
    }

    if (_updateInfo == null) return;

    final result = await _updateService.startFlexibleUpdate();
    if (result == AppUpdateResult.success) {
      _isDownloading = true;
      _prefs.setBool(_kUpdateDownloadedKey, true);
      notifyListeners();
    }
  }

  /// Completes the flexible update process by restarting the app.
  Future<void> completeUpdate() async {
    if (_isSimulated) {
      logger.i('UpdateProvider: Completing simulated update.');
      _isSimulated = false;
      _isDownloading = false;
      _prefs.setBool(_kUpdateDownloadedKey, false);
      notifyListeners();
      return;
    }

    await _updateService.completeFlexibleUpdate();
    // SharedPreferences will be cleared after restart if we implement a version check,
    // but for now we clear it before calling complete (though it might not finish writing).
    _prefs.setBool(_kUpdateDownloadedKey, false);
  }

  /// Simulates an available update for debug/testing purposes.
  void simulateUpdate() {
    _isSimulated = true;
    _isDownloading = false;
    _prefs.setBool(_kUpdateDownloadedKey, false);
    _updateInfo = null;
    notifyListeners();
  }
}
