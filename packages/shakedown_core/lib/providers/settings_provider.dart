import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/config/default_settings.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/providers/settings_init/settings_migrations.dart';
import 'package:shakedown_core/providers/settings_init/settings_pref_readers.dart';
import 'package:shakedown_core/providers/settings_init/settings_screensaver_pref_readers.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/utils/logger.dart';
import 'package:shakedown_core/utils/pwa_detection.dart';
import 'package:shakedown_core/utils/web_perf_hint.dart';
import 'package:shakedown_core/utils/web_runtime.dart';
import 'package:shakedown_core/ui/widgets/backgrounds/floating_spheres_background.dart';

part 'settings_provider_core.dart';
part 'settings_provider_initialization.dart';
part 'settings_provider_screensaver.dart';
part 'settings_provider_source_filters.dart';
part 'settings_provider_web.dart';

enum DevHudMode {
  full,
  mini,
  micro;

  static DevHudMode fromString(String? value) {
    return DevHudMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DevHudMode.full,
    );
  }
}

enum WebEngineProfile {
  modern,
  legacy;

  static WebEngineProfile fromString(String? value) {
    return WebEngineProfile.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WebEngineProfile.modern,
    );
  }
}

class SettingsProvider extends ChangeNotifier
    with
        _SettingsProviderCoreFields,
        _SettingsProviderWebFields,
        _SettingsProviderScreensaverFields,
        _SettingsProviderSourceFiltersFields,
        _SettingsProviderCoreExtension,
        _SettingsProviderWebExtension,
        _SettingsProviderScreensaverExtension,
        _SettingsProviderSourceFiltersExtension,
        _SettingsProviderInitializationExtension {
  SettingsProvider(this._prefs, {this.isTv = false}) {
    _init();
    _setupUiScaleChannel();
  }

  @override
  final SharedPreferences _prefs;
  SharedPreferences get prefs => _prefs;

  @override
  final bool isTv;

  bool showExpandIcon = false;
}
