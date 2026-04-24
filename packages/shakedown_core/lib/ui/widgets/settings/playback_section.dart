import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/audio/web_playback_power_policy.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/ui/widgets/section_card.dart';
import 'package:shakedown_core/ui/widgets/settings/highlightable_setting.dart';
import 'package:shakedown_core/ui/widgets/settings/random_probability_card.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_switch_list_tile.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/utils/pwa_detection.dart';
import 'package:shakedown_core/utils/utils.dart';
import 'package:lucide_icons/lucide_icons.dart';

part 'playback_section_build.dart';
part 'playback_section_web.dart';

class PlaybackSection extends StatelessWidget {
  final double scaleFactor;
  final bool initiallyExpanded;
  final String? activeHighlightKey;
  final int highlightTriggerCount;
  final Map<String, GlobalKey> settingKeys;
  final Function(String) onScrollToSetting;
  final bool isHighlightSettingMatching;

  const PlaybackSection({
    super.key,
    required this.scaleFactor,
    required this.initiallyExpanded,
    required this.activeHighlightKey,
    required this.highlightTriggerCount,
    required this.settingKeys,
    required this.onScrollToSetting,
    required this.isHighlightSettingMatching,
  });

  @override
  Widget build(BuildContext context) => _buildPlaybackSection(context);
}
