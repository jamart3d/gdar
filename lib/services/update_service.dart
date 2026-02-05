import 'package:in_app_update/in_app_update.dart';
import 'package:logger/logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  /// Opens the app's Play Store page.
  Future<void> openStore() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;
      final url = Uri.parse('market://details?id=$packageName');
      final webUrl = Uri.parse(
          'https://play.google.com/store/apps/details?id=$packageName');

      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        _logger.e('UpdateService: Could not launch Play Store URL.');
      }
    } catch (e) {
      _logger.e('UpdateService: Error opening store: $e');
    }
  }

  /// Starts a flexible update process.
  /// The user can continue using the app while the update downloads.
  /// [DEPRECATED] Use openStore() instead.
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
  /// [DEPRECATED] Use openStore() instead.
  Future<void> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      _logger.e('Error completing flexible update: $e');
    }
  }
}
