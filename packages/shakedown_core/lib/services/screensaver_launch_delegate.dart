typedef ScreensaverLaunch =
    Future<void> Function({bool allowPermissionPrompts});

class ScreensaverLaunchDelegate {
  const ScreensaverLaunchDelegate(this.launch);

  final ScreensaverLaunch launch;
}
