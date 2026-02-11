import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/styles/app_typography.dart';
import 'package:shakedown/ui/styles/font_config.dart';
import 'package:shakedown/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown/ui/widgets/onboarding/onboarding_components.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';

class SetupPage extends StatefulWidget {
  final double scaleFactor;
  final bool dontShowAgain;
  final ValueChanged<bool> onDontShowAgainChanged;
  final VoidCallback onFinish;

  const SetupPage({
    super.key,
    required this.scaleFactor,
    required this.dontShowAgain,
    required this.onDontShowAgainChanged,
    required this.onFinish,
  });

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return LayoutBuilder(builder: (context, constraints) {
      final isTv = context.watch<DeviceService>().isTv;

      Widget content = Padding(
        padding: EdgeInsets.symmetric(horizontal: isTv ? 48.0 : 24.0),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, animValue, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - animValue)),
              child: Opacity(
                opacity: animValue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    OnboardingComponents.buildSectionHeader(context,
                        'Customize Your Experience', widget.scaleFactor),
                    const SizedBox(height: 20),
                    Text(
                      'Font Selection',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontSize:
                            AppTypography.responsiveFontSize(context, 14.0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        _buildFontChip(context, 'default', 'Roboto', settings,
                            widget.scaleFactor),
                        _buildFontChip(context, 'caveat', 'Caveat', settings,
                            widget.scaleFactor),
                        _buildFontChip(context, 'permanent_marker',
                            'Permanent Marker', settings, widget.scaleFactor),
                        _buildFontChip(context, 'rock_salt', 'Rock Salt',
                            settings, widget.scaleFactor),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Preferences',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontSize:
                            AppTypography.responsiveFontSize(context, 14.0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        Builder(
                          builder: (context) {
                            final isTv = context.watch<DeviceService>().isTv;
                            Widget chip = FilterChip(
                              label: Text('UI Scale',
                                  style: TextStyle(
                                      fontSize:
                                          AppTypography.responsiveFontSize(
                                              context, 12.0))),
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
                                fontWeight: FontWeight.normal,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            );

                            if (isTv) {
                              chip = TvFocusWrapper(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  settings.toggleUiScale();
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: chip,
                              );
                            }
                            return chip;
                          },
                        ),
                        Builder(
                          builder: (context) {
                            final isTv = context.watch<DeviceService>().isTv;
                            Widget chip = FilterChip(
                              label: Text('Dark Mode',
                                  style: TextStyle(
                                      fontSize:
                                          AppTypography.responsiveFontSize(
                                              context, 12.0))),
                              selected: themeProvider.isDarkMode,
                              onSelected: (bool selected) {
                                _handleDarkModeToggle(
                                    selected, themeProvider, settings);
                              },
                              showCheckmark: false,
                              selectedColor: colorScheme.primaryContainer,
                              labelStyle: TextStyle(
                                color: themeProvider.isDarkMode
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                                fontWeight: FontWeight.normal,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            );

                            if (isTv) {
                              chip = TvFocusWrapper(
                                onTap: () {
                                  _handleDarkModeToggle(
                                      !themeProvider.isDarkMode,
                                      themeProvider,
                                      settings);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: chip,
                              );
                            }
                            return chip;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildDontShowAgainCheckbox(context, theme),
                    const SizedBox(height: 16),
                    _buildGetStartedButton(context, colorScheme, theme),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      );

      if (isTv) return content;

      return SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: constraints.maxWidth,
            child: content,
          ),
        ),
      );
    });
  }

  Widget _buildFontChip(BuildContext context, String fontKey, String label,
      SettingsProvider settings, double scaleFactor) {
    final isSelected = settings.appFont == fontKey;
    final colorScheme = Theme.of(context).colorScheme;
    final config = FontConfig.get(fontKey);
    final mediaQuery = MediaQuery.of(context);
    final fixedBaseSize = 12.0 * scaleFactor * mediaQuery.textScaler.scale(1.0);

    final normalizedStyle = TextStyle(
      fontFamily: config.fontFamily,
      fontSize: fixedBaseSize * config.scaleFactor,
      height: config.lineHeight,
      letterSpacing: config.letterSpacing,
      fontWeight: config.adjustWeight(FontWeight.normal),
    );

    return SizedBox(
      height: 40 * scaleFactor,
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(
                fontFamily: config.fontFamily,
              ),
        ),
        child: Builder(
          builder: (context) {
            final isTv = context.watch<DeviceService>().isTv;
            Widget chip = FilterChip(
              label: Text(
                label,
                style: normalizedStyle,
                textAlign: TextAlign.center,
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
              labelStyle: normalizedStyle.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scaleFactor,
                vertical: 8 * scaleFactor,
              ),
            );

            if (isTv) {
              chip = TvFocusWrapper(
                onTap: () {
                  HapticFeedback.selectionClick();
                  settings.setAppFont(fontKey);
                },
                borderRadius: BorderRadius.circular(8),
                child: chip,
              );
            }
            return chip;
          },
        ),
      ),
    );
  }

  Widget _buildDontShowAgainCheckbox(BuildContext context, ThemeData theme) {
    final isTv = context.watch<DeviceService>().isTv;

    Widget checkbox = InkWell(
      onTap: () => widget.onDontShowAgainChanged(!widget.dontShowAgain),
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
                value: widget.dontShowAgain,
                onChanged: (val) => widget.onDontShowAgainChanged(val ?? false),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "Don't show again",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: AppTypography.responsiveFontSize(context, 12.0),
              ),
            ),
          ],
        ),
      ),
    );

    if (isTv) {
      checkbox = TvFocusWrapper(
        onTap: () => widget.onDontShowAgainChanged(!widget.dontShowAgain),
        borderRadius: BorderRadius.circular(8),
        child: checkbox,
      );
    }

    return checkbox;
  }

  void _handleDarkModeToggle(
      bool selected, ThemeProvider themeProvider, SettingsProvider settings) {
    HapticFeedback.selectionClick();
    themeProvider.toggleTheme();

    // Sync True Black with Dark Mode
    if (selected) {
      if (!settings.useTrueBlack) {
        settings.toggleUseTrueBlack();
      }
    } else {
      if (settings.useTrueBlack) {
        settings.toggleUseTrueBlack();
      }
    }
  }

  Widget _buildGetStartedButton(
      BuildContext context, ColorScheme colorScheme, ThemeData theme) {
    final isTv = context.watch<DeviceService>().isTv;

    Widget button = AnimatedGradientBorder(
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
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
        ),
        child: ElevatedButton(
          onPressed: widget.onFinish,
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
              fontSize: AppTypography.responsiveFontSize(context, 16.0),
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );

    if (isTv) {
      button = TvFocusWrapper(
        onTap: widget.onFinish,
        borderRadius: BorderRadius.circular(30),
        child: button,
      );
    }

    return button;
  }
}
