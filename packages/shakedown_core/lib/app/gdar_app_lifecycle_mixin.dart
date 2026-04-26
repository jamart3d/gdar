import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/automation/automation_executor.dart';
import 'package:shakedown_core/services/automation/automation_step.dart';
import 'package:shakedown_core/services/automation/automation_step_parser.dart';
import 'package:shakedown_core/services/deep_link_service.dart';
import 'package:shakedown_core/services/inactivity_service.dart';
import 'package:shakedown_core/ui/screens/screensaver_screen.dart';
import 'package:shakedown_core/ui/navigation/route_names.dart';
import 'package:shakedown_core/utils/logger.dart';

/// A mixin to handle common GDAR application lifecycle logic across platforms.
///
/// This includes deep links, automation, inactivity monitoring (screensaver),
/// and shared settings synchronization.
mixin GdarAppLifecycleMixin<T extends StatefulWidget> on State<T> {
  late final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  InactivityService? inactivityService;
  DeepLinkService? deepLinkService;
  StreamSubscription? linkSubscription;

  bool isScreensaverActive = false;
  String? currentRouteName;

  /// Override this to provide the platform-specific isTv flag.
  bool get isTv;

  /// Override this to provide the settings provider instance.
  SettingsProvider get settingsProvider;

  /// Initialize lifecycle services.
  void initLifecycle({bool enableDeepLinks = true}) {
    final settings = settingsProvider;

    if (isTv) {
      inactivityService = InactivityService(
        onInactivityTimeout: handleInactivityTimeout,
        initialDuration: Duration(
          minutes: settings.oilScreensaverInactivityMinutes,
        ),
      );
    }

    if (enableDeepLinks) {
      initDeepLinks();
    }
  }

  /// Dispose lifecycle services.
  void disposeLifecycle() {
    inactivityService?.dispose();
    linkSubscription?.cancel();
    deepLinkService?.dispose();
  }

  /// Handles route changes to suppress screensaver on certain screens (e.g. Settings).
  void handleRouteChanged(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && name != currentRouteName) {
      logger.d('GdarAppLifecycle: route changed name=$name');
      currentRouteName = name;
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
    }
  }

  /// Synchronizes inactivity service state based on current settings and route.
  void syncInactivityService(SettingsProvider settings) {
    final service = inactivityService;
    if (!isTv || service == null) return;

    service.updateDuration(
      Duration(minutes: settings.oilScreensaverInactivityMinutes),
    );

    final isOnBlockedRoute = currentRouteName == ShakedownRouteNames.tvSettings;

    if (settings.useOilScreensaver &&
        !isScreensaverActive &&
        !isOnBlockedRoute) {
      service.start();
    } else {
      service.stop();
    }
  }

  /// Launches the screensaver.
  Future<void> launchScreensaver({
    required bool allowPermissionPrompts,
    required String source,
  }) async {
    if (!mounted || isScreensaverActive) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    logger.i('Launching screensaver from $source (isTv=$isTv)');

    inactivityService?.stop();
    setState(() => isScreensaverActive = true);

    try {
      // Yield to event loop to avoid navigator lock assertions.
      await Future.delayed(Duration.zero);
      if (!mounted || !isScreensaverActive) return;

      await navigator.push(
        ScreensaverScreen.route(allowPermissionPrompts: allowPermissionPrompts),
      );
    } catch (e) {
      logger.e('Screensaver launch failed', error: e);
    } finally {
      if (mounted) {
        setState(() => isScreensaverActive = false);
        final settings = settingsProvider;
        if (isTv && settings.useOilScreensaver) {
          inactivityService?.start();
        }
      }
    }
  }

  Future<void> handleInactivityTimeout() {
    return launchScreensaver(allowPermissionPrompts: false, source: 'timeout');
  }

  void initDeepLinks() {
    deepLinkService = DeepLinkService();
    deepLinkService!.init();

    linkSubscription = deepLinkService!.uriStream.listen((Uri? uri) async {
      if (uri == null || !mounted) return;

      if (uri.scheme == 'shakedown') {
        if (uri.path == 'automate' || uri.host == 'automate') {
          final rawSteps =
              uri.queryParameters['steps']?.split(',') ?? <String>[];
          await handleAutomation(parseAutomationSteps(rawSteps));
        } else if (uri.host == 'settings') {
          final key = uri.queryParameters['key'];
          final value = uri.queryParameters['value'];
          final settings = settingsProvider;

          if (key != null && value != null) {
            await applyAutomationSetting(
              settings: settings,
              key: key,
              value: value,
            );
          }
        }
      }
    });
  }

  Future<void> handleAutomation(List<AutomationStep> steps) async {
    final state = navigatorKey.currentState;
    if (state == null) {
      Future.delayed(
        const Duration(milliseconds: 500),
        () => handleAutomation(steps),
      );
      return;
    }

    final automationContext = state.context;
    final audioProvider = Provider.of<AudioProvider>(
      automationContext,
      listen: false,
    );

    final executor = AutomationExecutor(
      playRandomShow: audioProvider.playRandomShow,
      delay: Future<void>.delayed,
      applySetting: (key, value) => applyAutomationSetting(
        settings: settingsProvider,
        key: key,
        value: value,
      ),
      launchScreensaver: () async {
        if (isTv) {
          await launchScreensaver(
            allowPermissionPrompts: true,
            source: 'automation',
          );
        } else if (automationContext.mounted) {
          await ScreensaverScreen.show(automationContext);
        }
      },
    );

    await executor.execute(steps);
  }

  Future<void> applyAutomationSetting({
    required SettingsProvider settings,
    required String key,
    required String value,
  }) async {
    if (key == 'oil_enable_audio_reactivity') {
      final target = value == 'true';
      if (settings.oilEnableAudioReactivity != target) {
        await settings.toggleOilEnableAudioReactivity();
      }
    } else if (key == 'oil_audio_graph_mode') {
      await settings.setOilAudioGraphMode(value);
    } else if (key == 'force_tv') {
      await settings.setForceTv(value == 'true');
    } else if (key == 'oil_screensaver_mode') {
      await settings.setOilScreensaverMode(value);
    } else if (key == 'oil_beat_detector_mode') {
      // Added support for beat detector mode automation
      await settings.setOilBeatDetectorMode(value);
    }
  }
}
