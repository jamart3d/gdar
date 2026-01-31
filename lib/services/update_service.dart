import 'package:in_app_update/in_app_update.dart';
import 'package:logger/logger.dart';

/// Service to handle in-app updates using the Play Store API.
class UpdateService {
  final _logger = Logger();

  /// Checks if an update is available on the Play Store.
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      return info;
    } catch (e) {
      if (e.toString().contains('-10')) {
        _logger.i(
            'UpdateService: App not owned by Play Store user (side-loaded). Skipping check.');
      } else {
        _logger.e('UpdateService: Error checking for update: $e');
      }
      return null;
    }
  }

  /// Starts a flexible update process.
  /// The user can continue using the app while the update downloads.
  Future<AppUpdateResult?> startFlexibleUpdate() async {
    try {
      return await InAppUpdate.startFlexibleUpdate();
    } catch (e) {
      _logger.e('Error starting flexible update: $e');
      return AppUpdateResult.inAppUpdateFailed;
    }
  }

  /// Completes the flexible update process by restarting the app.
  /// Should only be called after the download is finished.
  Future<void> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      _logger.e('Error completing flexible update: $e');
    }
  }
}
