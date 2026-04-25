import 'package:flutter/widgets.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/services/audio_cache_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/screensaver_launch_delegate.dart';

@immutable
class GdarAppProviderOverrides {
  final SettingsProvider? settingsProvider;
  final ShowListProvider? showListProvider;
  final AudioProvider? audioProvider;
  final AudioCacheService? audioCacheService;
  final DeviceService? deviceService;
  final ScreensaverLaunchDelegate? screensaverLaunchDelegate;

  const GdarAppProviderOverrides({
    this.settingsProvider,
    this.showListProvider,
    this.audioProvider,
    this.audioCacheService,
    this.deviceService,
    this.screensaverLaunchDelegate,
  });
}
