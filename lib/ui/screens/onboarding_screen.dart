import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/screens/show_list_screen.dart';
import 'package:shakedown/ui/screens/splash_screen.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shakedown/ui/widgets/shakedown_title.dart';
import 'package:shakedown/ui/styles/app_typography.dart';
import 'package:shakedown/ui/widgets/onboarding/welcome_page.dart';
import 'package:shakedown/ui/widgets/onboarding/tips_page.dart';
import 'package:shakedown/ui/widgets/onboarding/setup_page.dart';
import 'package:shakedown/providers/update_provider.dart';

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

  void _startUpdate() {
    context.read<UpdateProvider>().startUpdate();
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
    final scaleFactor = FontLayoutConfig.getEffectiveScale(context, settings);

    final updateProvider = context.watch<UpdateProvider>();

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
                  WelcomePage(
                    scaleFactor: scaleFactor,
                    archiveReachable: _archiveReachable,
                    updateInfo: updateProvider.updateInfo,
                    isDownloading: updateProvider.isDownloading,
                    isSimulated: updateProvider.isSimulated,
                    onUpdateSelected: _startUpdate,
                  ),
                  TipsPage(scaleFactor: scaleFactor),
                  SetupPage(
                    scaleFactor: scaleFactor,
                    dontShowAgain: _dontShowAgain,
                    onDontShowAgainChanged: (val) {
                      setState(() {
                        _dontShowAgain = val;
                      });
                    },
                    onFinish: _finishOnboarding,
                  ),
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
          width: 80 * scaleFactor,
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
}
