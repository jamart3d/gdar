import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
import 'package:shakedown/ui/styles/app_typography.dart';
import 'package:shakedown/ui/styles/font_config.dart';
import 'package:shakedown/ui/widgets/show_list/animated_dice_icon.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _dontShowAgain = false;
  String? _version;
  bool? _archiveReachable;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _checkArchiveReachability();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
      });
    }
  }

  Future<void> _checkArchiveReachability() async {
    try {
      await http
          .head(Uri.parse('https://archive.org'))
          .timeout(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _archiveReachable = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _archiveReachable = false;
        });
      }
    }
  }

  void _finishOnboarding() {
    final settingsProvider = context.read<SettingsProvider>();

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

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
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
        child: Column(
          children: [
            _buildCommonHeader(context, scaleFactor),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(context, scaleFactor),
                  _buildTipsPage(context, scaleFactor),
                  _buildSetupPage(
                      context, settings, themeProvider, scaleFactor),
                ],
              ),
            ),
            _buildBottomNav(context, scaleFactor),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, double scaleFactor) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLastPage = _currentPage == 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dots Indicator
          Row(
            children: List.generate(3, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 8),
                height: 8 * scaleFactor,
                width: (_currentPage == index ? 24 : 8) * scaleFactor,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          // Navigation Button
          // Navigation Button (Hidden but preserved for layout stability)
          IgnorePointer(
            ignoring: isLastPage,
            child: AnimatedOpacity(
              opacity: isLastPage ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: TextButton(
                onPressed: _nextPage,
                child: Text(
                  'Next',
                  style: TextStyle(
                    fontSize: AppTypography.responsiveFontSize(context, 16.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonHeader(BuildContext context, double scaleFactor) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: 20),
        Container(
          width: 80 *
              scaleFactor, // Slightly smaller header for secondary pages or uniform look
          height: 80 * scaleFactor,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.music_note_rounded,
            size: 40 * scaleFactor,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: scaleFactor, end: scaleFactor),
          builder: (context, animatedScale, child) {
            return Column(
              children: [
                ShakedownTitle(fontSize: 24 * animatedScale),
                const SizedBox(height: 4),
                if (_version != null)
                  Text(
                    'Version $_version',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize:
                          AppTypography.responsiveFontSize(context, 12.0) *
                              animatedScale,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildWelcomePage(BuildContext context, double scaleFactor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.watch<SettingsProvider>();

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Welcome friend! and many thanks for helping with this closed test.\nThis app is a lightweight streaming music player.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  fontSize: AppTypography.responsiveFontSize(
                      context,
                      (settings.uiScale && settings.appFont == 'caveat')
                          ? 14.5
                          : 16.0),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Archive.org Item (Top Priority)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '•',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize:
                            AppTypography.responsiveFontSize(context, 18.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.3,
                            fontSize: AppTypography.responsiveFontSize(
                                context,
                                (settings.uiScale &&
                                        settings.appFont == 'caveat')
                                    ? 12.5
                                    : 14.0),
                          ),
                          children: [
                            const TextSpan(
                                text: 'All audio is streamed directly from '),
                            TextSpan(
                              text: 'Archive.org',
                              style: TextStyle(
                                color: (_archiveReachable == false)
                                    ? const Color(0xFFEF4444) // Explicit Red
                                    : null,
                                fontWeight: (_archiveReachable == false)
                                    ? FontWeight.bold
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildBulletPoint(
                  context,
                  'Dive into an almost endless list of live Grateful Dead shows',
                  scaleFactor),
              _buildBulletPoint(context,
                  'Play a random show or choose a specific date', scaleFactor),
              _buildBulletPoint(
                  context,
                  'Filter source types: Matrix, Betty Board, Soundboard, etc.',
                  scaleFactor),
              _buildBulletPoint(context, 'Gapless playback', scaleFactor),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTipsPage(BuildContext context, double scaleFactor) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildSectionHeader(context, 'Quick Tips', scaleFactor),
              const SizedBox(height: 20),
              _buildTipRow(
                  context,
                  _buildIconBubble(context, Icons.touch_app_rounded),
                  'Long press a show card for playing, single tap track play is off by default',
                  scaleFactor),
              const SizedBox(height: 16),
              _buildTipRow(
                  context,
                  SizedBox(
                    width: 28 * scaleFactor,
                    height: 28 * scaleFactor,
                    child: FittedBox(
                      child: AnimatedDiceIcon(
                        onPressed: () {}, // Dummy callback
                        isLoading: true, // Spin it!
                        changeFaces:
                            false, // Don't change faces per user request
                      ),
                    ),
                  ),
                  'Tap to randomly select and discover a show you may not have heard',
                  scaleFactor),
              const SizedBox(height: 16),
              _buildTipRow(
                  context,
                  _buildIconBubble(context, Icons.star_rate_rounded),
                  'Rate shows for random selection to use',
                  scaleFactor),
              const SizedBox(height: 16),
              _buildTipRow(
                  context,
                  _buildIconBubble(context, Icons.settings_rounded),
                  'Check out the settings for more options and usage instructions',
                  scaleFactor),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSetupPage(BuildContext context, SettingsProvider settings,
      ThemeProvider themeProvider, double scaleFactor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(
                    milliseconds: 600), // Material 3 expressive duration
                curve: Curves.easeOutCubic, // Expressive deceleration
                tween:
                    Tween<double>(begin: 0.0, end: 1.0), // Animate from 0 to 1
                builder: (context, animValue, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - animValue)), // Slide up 20px
                    child: Opacity(
                      opacity: animValue, // Fade in
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildSectionHeader(context,
                              'Customize Your Experience', scaleFactor),
                          const SizedBox(height: 20),
                          Text(
                            'Font Selection',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontSize: AppTypography.responsiveFontSize(
                                  context, 14.0),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              _buildFontChip(context, 'default', 'Roboto',
                                  settings, scaleFactor),
                              _buildFontChip(context, 'caveat', 'Caveat',
                                  settings, scaleFactor),
                              _buildFontChip(context, 'permanent_marker',
                                  'Permanent Marker', settings, scaleFactor),
                              _buildFontChip(context, 'rock_salt', 'Rock Salt',
                                  settings, scaleFactor),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Preferences',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurface,
                              fontSize: AppTypography.responsiveFontSize(
                                  context, 14.0),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              FilterChip(
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
                              ),
                              FilterChip(
                                label: Text('Dark Mode',
                                    style: TextStyle(
                                        fontSize:
                                            AppTypography.responsiveFontSize(
                                                context, 12.0))),
                                selected: themeProvider.isDarkMode,
                                onSelected: (bool selected) {
                                  HapticFeedback.selectionClick();
                                  themeProvider.toggleTheme();

                                  // Sync True Black with Dark Mode
                                  if (selected) {
                                    // Turning ON Dark Mode -> Turn ON True Black
                                    if (!settings.useTrueBlack) {
                                      settings.toggleUseTrueBlack();
                                    }
                                  } else {
                                    // Turning OFF Dark Mode -> Turn OFF True Black
                                    if (settings.useTrueBlack) {
                                      settings.toggleUseTrueBlack();
                                    }
                                  }
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
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _dontShowAgain = !_dontShowAgain;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
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
                                      fontSize:
                                          AppTypography.responsiveFontSize(
                                              context, 12.0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                color: colorScheme.surface,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: ElevatedButton(
                                onPressed: _finishOnboarding,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: Text(
                                  'Get Started',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: AppTypography.responsiveFontSize(
                                        context, 16.0),
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, double scaleFactor) {
    // Normalize fontSize across fonts by compensating for their scaleFactor
    final settings = Provider.of<SettingsProvider>(context);
    final fontConfig = FontConfig.get(settings.appFont);
    final mediaQuery = MediaQuery.of(context);

    // Base size 21px, divided by font's scaleFactor to normalize visual size
    final normalizedFontSize = (21.0 / fontConfig.scaleFactor) *
        scaleFactor *
        mediaQuery.textScaler.scale(1.0);

    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize:
                normalizedFontSize, // Normalized size keeps title position fixed
          ),
    );
  }

  Widget _buildFontChip(BuildContext context, String fontKey, String label,
      SettingsProvider settings, double scaleFactor) {
    final isSelected = settings.appFont == fontKey;
    final colorScheme = Theme.of(context).colorScheme;

    // Get font configuration for THIS chip (not the selected app font)
    final config = FontConfig.get(fontKey);

    // Calculate base size WITHOUT app's font scale factor applied
    // This prevents chips from resizing when app font changes
    final mediaQuery = MediaQuery.of(context);
    final uiScale = scaleFactor; // Only UI Scale toggle should affect chip size
    final fixedBaseSize = 12.0 * uiScale * mediaQuery.textScaler.scale(1.0);

    // Apply this chip's normalization to match all chips to same visual size
    final normalizedStyle = TextStyle(
      fontFamily: config.fontFamily,
      fontSize: fixedBaseSize *
          config.scaleFactor, // Apply chip-specific normalization
      height: config.lineHeight,
      letterSpacing: config.letterSpacing,
      fontWeight: config.adjustWeight(FontWeight.normal),
    );

    // Create isolated theme for this chip to force its font family
    return SizedBox(
      height: 40 * scaleFactor, // Scale height with UI Scale
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(
                fontFamily: config.fontFamily, // Force this chip's font
              ),
        ),
        child: FilterChip(
          label: Text(
            label,
            style: normalizedStyle, // Explicitly use this font's style
            textAlign: TextAlign.center, // Center text horizontally
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
            fontFamily: config
                .fontFamily, // Force font family again to prevent theme override
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scaleFactor,
            vertical: 8 * scaleFactor,
          ), // Scale padding with UI Scale
        ),
      ),
    );
  }

  Widget _buildIconBubble(BuildContext context, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: Icon(icon,
          size: AppTypography.responsiveFontSize(context, 20.0),
          color: colorScheme.primary),
    );
  }

  Widget _buildTipRow(
      BuildContext context, Widget leading, String text, double scaleFactor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        leading,
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.2,
                  fontSize: AppTypography.responsiveFontSize(
                      context,
                      (Provider.of<SettingsProvider>(context).uiScale &&
                              Provider.of<SettingsProvider>(context).appFont ==
                                  'caveat')
                          ? 12.5
                          : 14.0),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(
      BuildContext context, String text, double scaleFactor) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: AppTypography.responsiveFontSize(context, 18.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                    fontSize: AppTypography.responsiveFontSize(
                        context,
                        (Provider.of<SettingsProvider>(context).uiScale &&
                                Provider.of<SettingsProvider>(context)
                                        .appFont ==
                                    'caveat')
                            ? 12.5
                            : 14.0),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
