import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shakedown/services/update_service.dart';
import 'package:shakedown/utils/logger.dart';

/// Provider to manage the app update state and lifecycle.
class UpdateProvider with ChangeNotifier {
  final UpdateService _updateService = UpdateService();

  AppUpdateInfo? _updateInfo;
  bool _isDownloading = false;
  bool _isSimulated = false;

  /// Current update information from the Play Store or simulation.
  AppUpdateInfo? get updateInfo => _updateInfo;

  /// Whether a flexible update is currently being downloaded.
  bool get isDownloading => _isDownloading;

  /// Whether the current update state is simulated for testing.
  bool get isSimulated => _isSimulated;

  /// Checks for available updates on the Play Store.
  Future<void> checkForUpdate() async {
    if (_isSimulated) return;
    if (kDebugMode) {
      logger.d('UpdateProvider: Skipping update check in Debug mode.');
      return;
    }
    final info = await _updateService.checkForUpdate();
    _updateInfo = info;
    notifyListeners();
  }

  /// Starts the flexible update process.
  Future<void> startUpdate() async {
    if (_isSimulated) {
      _isDownloading = true;
      notifyListeners();
      return;
    }

    if (_updateInfo == null) return;

    final result = await _updateService.startFlexibleUpdate();
    if (result == AppUpdateResult.success) {
      _isDownloading = true;
      notifyListeners();
    }
  }

  /// Simulates an available update for debug/testing purposes.
  void simulateUpdate() {
    _isSimulated = true;
    _isDownloading = false;
    // Mocking AppUpdateInfo is tricky because it's a platform-specific object return from the plugin.
    // However, the UpdateBanner logic primarily checks availability status.
    // We'll use a placeholder if possible, or adjust the banner to handle a "simulated" flag.
    _updateInfo = null; // We'll trigger the banner via a different flag or mock
    notifyListeners();
  }
}
