import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_list_tile.dart';
import 'package:shakedown_core/services/device_service.dart';

import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/utils/color_generator.dart';
import 'package:shakedown_core/utils/utils.dart';
import 'package:gdar_mobile/ui/widgets/pulsing_heart_icon.dart';
import 'package:shakedown_core/providers/theme_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final audioProvider = context.watch<AudioProvider>();

    Color? backgroundColor;
    // Only apply custom background color if NOT in "True Black" mode.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    if (!isTrueBlackMode &&
        settingsProvider.highlightCurrentShowCard &&
        audioProvider.currentShow != null) {
      String seed = audioProvider.currentShow!.name;
      if (audioProvider.currentShow!.sources.length > 1 &&
          audioProvider.currentSource != null) {
        seed = audioProvider.currentSource!.id;
      }
      backgroundColor = ColorGenerator.getColor(seed,
          brightness: Theme.of(context).brightness);
    }

    final baseTheme = Theme.of(context);
    final effectiveBackgroundColor =
        backgroundColor ?? baseTheme.scaffoldBackgroundColor;

    final effectiveTheme = baseTheme.copyWith(
      scaffoldBackgroundColor: effectiveBackgroundColor,
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: effectiveBackgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
    );

    return AnimatedTheme(
      data: effectiveTheme,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: settingsProvider.uiScale
              ? const TextScaler.linear(1.2)
              : const TextScaler.linear(1.0),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('About Shakedown'),
          ),
          body: const SingleChildScrollView(
            child: AboutBody(),
          ),
        ),
      ),
    );
  }
}

class AboutBody extends StatelessWidget {
  const AboutBody({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          // App Icon / Logo Placeholder
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.music_note_rounded,
              size: 50,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Shakedown',
            style: textTheme.displayMedium?.copyWith(
              fontFamily:
                  context.read<DeviceService>().isTv ? 'RockSalt' : null,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          // Version 1.0.0
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              return Text(
                'Version ${snapshot.data!.version}',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'A simple, lightweight music player for select live grateful dead shows from Archive.org, featuring gapless playback and random show selection.',
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'All audio is streamed directly from Archive.org.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          _buildClickableLink(
            context,
            'Archive.org Terms of Use',
            'https://archive.org/about/terms.php',
            icon: Icons.gavel,
          ),
          const SizedBox(height: 16),
          _buildClickableLink(
            context,
            'Consider Donating to the Internet Archive',
            'https://archive.org/donate/',
            customIcon: PulsingHeartIcon(
              scaleFactor: 1.0,
              isFruit:
                  context.read<ThemeProvider>().themeStyle == ThemeStyle.fruit,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (context.mounted) {
        showMessage(context, 'Could not open browser: $e');
      }
    }
  }

  Widget _buildClickableLink(BuildContext context, String text, String url,
      {IconData? icon, Widget? customIcon}) {
    final colorScheme = Theme.of(context).colorScheme;
    return TvListTile(
      leading: customIcon ??
          (icon != null ? Icon(icon, color: colorScheme.primary) : null),
      title: Text(
        text,
        style: TextStyle(
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
      onTap: () => _launchUrl(context, url),
    );
  }
}
