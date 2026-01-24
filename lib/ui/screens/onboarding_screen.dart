import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/screens/show_list_screen.dart';
import 'package:shakedown/ui/screens/splash_screen.dart';
import 'package:shakedown/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shakedown/ui/widgets/shakedown_title.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _dontShowAgain = false;
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
      });
    }
  }

  void _finishOnboarding() {
    final settingsProvider = context.read<SettingsProvider>();

    // Only mark as complete if the user checked the box.
    // If unchecked, the version remains 0, so it will show again next time (unless logic changes).
    // The requirement was "skip page at next load" toggle.
    // If "Don't show again" is TRUE, we complete onboarding.
    if (_dontShowAgain) {
      settingsProvider.completeOnboarding();
    }

    final nextScreen = settingsProvider.showSplashScreen
        ? const SplashScreen()
        : const ShowListScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubicEmphasized,
          );
          return FadeTransition(opacity: curvedAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, double scaleFactor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 10.5 * scaleFactor,
            ),
      ),
    );
  }

  Widget _buildFontChip(BuildContext context, String fontKey, String label,
      SettingsProvider settings, double scaleFactor) {
    final isSelected = settings.appFont == fontKey;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 4.0),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 8.5 * scaleFactor,
            fontFamily: fontKey == 'default'
                ? 'Roboto'
                : (label == 'Rock Salt' ? 'RockSalt' : label),
          ),
        ),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            HapticFeedback.selectionClick();
            settings.setAppFont(fontKey);
          }
        },
        showCheckmark: false,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(
          fontFamily: fontKey == 'default'
              ? 'Roboto'
              : (label == 'Rock Salt' ? 'RockSalt' : label),
          color: isSelected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildTipRow(
      BuildContext context, IconData icon, String text, double scaleFactor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child:
                Icon(icon, size: 16 * scaleFactor, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.2,
                    fontSize: 8.5 * scaleFactor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(
      BuildContext context, String text, double scaleFactor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '•',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 14 * scaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                    fontSize: 9.5 * scaleFactor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final scaleFactor = FontLayoutConfig.getEffectiveScale(context, settings);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // 1. Header (Simple, dynamic font, version)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
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
                    const SizedBox(height: 8),
                    const ShakedownTitle(fontSize: 24),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 20 * scaleFactor,
                      child: _version == null
                          ? const SizedBox.shrink()
                          : Text(
                              'Version $_version',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 10.0 * scaleFactor,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 2),

              // 2. Welcome Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Welcome friend! and many thanks for helping with the closed testing of this app. A lightweight music player.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    fontSize: 10.5 * scaleFactor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: Column(
                  children: [
                    _buildBulletPoint(
                        context,
                        'Dive into an almost endless list of live Grateful Dead shows',
                        scaleFactor),
                    _buildBulletPoint(
                        context,
                        'Play a random show or choose a specific date',
                        scaleFactor),
                    _buildBulletPoint(
                        context,
                        'Filter source types: Matrix, Betty Board, Soundboard, etc.',
                        scaleFactor),
                    _buildBulletPoint(
                        context,
                        'All audio is streamed directly from Archive.org',
                        scaleFactor),
                    _buildBulletPoint(context, 'Gapless playback', scaleFactor),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 3. Quick Tips Section
              _buildSectionHeader(context, 'Quick Tips', scaleFactor),
              _buildTipRow(
                  context,
                  Icons.touch_app_rounded,
                  'Long press a show card for playing, single tap track play is off by default',
                  scaleFactor),
              _buildTipRow(
                  context,
                  Icons.question_mark_rounded,
                  'Tap to randomly select and discover a show you may not have heard',
                  scaleFactor),
              _buildTipRow(context, Icons.star_rate_rounded,
                  'Rate shows for random selection to use', scaleFactor),
              _buildTipRow(
                  context,
                  Icons.settings_rounded,
                  'Check out the settings for more options and usage instructions',
                  scaleFactor),

              const SizedBox(height: 8),

              // 4. Customize Section
              _buildSectionHeader(
                  context, 'Customize Your Experience', scaleFactor),

              Text(
                'Font Selection',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: 10.5 * scaleFactor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4.0,
                runSpacing: 4.0,
                children: [
                  _buildFontChip(
                      context, 'default', 'Roboto', settings, scaleFactor),
                  _buildFontChip(
                      context, 'caveat', 'Caveat', settings, scaleFactor),
                  _buildFontChip(context, 'permanent_marker',
                      'Permanent Marker', settings, scaleFactor),
                  _buildFontChip(
                      context, 'rock_salt', 'Rock Salt', settings, scaleFactor),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Preferences',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: 10.5 * scaleFactor,
                ),
              ),
              const SizedBox(height: 4),

              // Preferences Toggle Chips
              Wrap(
                spacing: 4.0,
                runSpacing: 4.0,
                children: [
                  // UI Scale Chip
                  FilterChip(
                    label: Text('UI Scale',
                        style: TextStyle(fontSize: 8.5 * scaleFactor)),
                    selected: settings.uiScale,
                    onSelected: (bool selected) {
                      HapticFeedback.selectionClick();
                      settings.toggleUiScale();
                    },
                    showCheckmark: false,
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: settings.uiScale
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      fontWeight: settings.uiScale
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),

                  // Dark Mode Chip
                  FilterChip(
                    label: Text('Dark Mode',
                        style: TextStyle(fontSize: 8.5 * scaleFactor)),
                    selected: themeProvider.isDarkMode,
                    onSelected: (bool selected) {
                      HapticFeedback.selectionClick();
                      themeProvider.toggleTheme();

                      // If turning OFF Dark Mode, also disable True Black if it's on
                      if (!selected && settings.useTrueBlack) {
                        settings.toggleUseTrueBlack();
                      }
                    },
                    showCheckmark: false,
                    selectedColor: colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: themeProvider.isDarkMode
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      fontWeight: themeProvider.isDarkMode
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 5. Footer (Scrolls with content)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Don't show again Checkbox
                  InkWell(
                    onTap: () {
                      setState(() {
                        _dontShowAgain = !_dontShowAgain;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _dontShowAgain,
                              onChanged: (val) {
                                setState(() {
                                  _dontShowAgain = val ?? false;
                                });
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Don't show again",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 8.5 * scaleFactor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Get Started Button
                  // Get Started Button with RGB Animated Border
                  AnimatedGradientBorder(
                    borderRadius: 30,
                    borderWidth: 3,
                    colors: const [
                      Colors.red,
                      Colors.orange,
                      Colors.yellow,
                      Colors.green,
                      Colors.blue,
                      Colors.purple,
                      Colors.red,
                    ],
                    animationSpeed: 0.5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme
                            .surface, // Inner background matches surface
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ElevatedButton(
                        onPressed: _finishOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Get Started',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 11.0 * scaleFactor,
                            color: colorScheme
                                .primary, // Text uses primary color now
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
