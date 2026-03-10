import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/link.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/utils/utils.dart';

class ShnidBadge extends StatelessWidget {
  final String text;
  final bool showUnderline;
  final double scaleFactor;
  final VoidCallback? onTap;
  final bool interactive;
  final Uri? uri;

  const ShnidBadge({
    super.key,
    required this.text,
    this.showUnderline = false,
    this.scaleFactor = 1.0,
    this.onTap,
    this.interactive = true,
    this.uri,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final double effectiveScale =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    // Check for True Black mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    final List<Color> gradientColors;
    if (isTrueBlackMode) {
      gradientColors = [
        Colors.black,
        Colors.black,
      ];
    } else {
      gradientColors = [
        colorScheme.secondaryContainer.withValues(alpha: 0.7),
        colorScheme.secondaryContainer.withValues(alpha: 0.5),
      ];
    }

    final textColor = colorScheme.onSecondaryContainer;

    Widget content = Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: textColor.withValues(alpha: 0.5),
          fontSize: ((settingsProvider.appFont == 'rock_salt')
                  ? 7.5 * effectiveScale
                  : 9.0 * effectiveScale) *
              scaleFactor,
          height: (settingsProvider.appFont == 'rock_salt') ? 2.0 : 1.5,
          letterSpacing: (settingsProvider.appFont == 'rock_salt' ||
                  settingsProvider.appFont == 'permanent_marker')
              ? 1.5 * scaleFactor
              : 0.0),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textAlign: TextAlign.center,
    );

    if (showUnderline) {
      content = Container(
        padding: EdgeInsets.only(
          bottom: (settingsProvider.appFont == 'rock_salt') ? 3.0 : 1.0,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: textColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
        ),
        child: content,
      );
    }

    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final useNeumorphic = isFruit &&
        settingsProvider.useNeumorphism &&
        !settingsProvider.useTrueBlack;

    Widget badge = Container(
      padding: EdgeInsets.symmetric(
          horizontal: (isFruit ? 8 : 6) * scaleFactor,
          vertical: (isFruit ? 4 : 2.0) * scaleFactor),
      constraints: const BoxConstraints(maxWidth: 100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isFruit ? 10 : 8),
        boxShadow: useNeumorphic
            ? [] // Neumorphic wrapper handles shadows
            : [
                BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1))
              ],
      ),
      child: content,
    );

    Widget badgeWithTap = badge;
    if (interactive) {
      final semanticLabel = 'Open archive details for $text';
      if (uri != null) {
        badgeWithTap = Link(
          uri: uri,
          target: LinkTarget.blank,
          builder: (context, followLink) {
            final activate = onTap ??
                followLink ??
                () => launchArchiveDetails(text, context);
            return Semantics(
              link: true,
              button: true,
              label: semanticLabel,
              child: ExcludeSemantics(
                child: FocusableActionDetector(
                  enabled: true,
                  mouseCursor: SystemMouseCursors.click,
                  shortcuts: const <ShortcutActivator, Intent>{
                    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
                  },
                  actions: <Type, Action<Intent>>{
                    ActivateIntent: CallbackAction<ActivateIntent>(
                      onInvoke: (_) {
                        activate();
                        return null;
                      },
                    ),
                  },
                  child: GestureDetector(
                    onTap: activate,
                    behavior: HitTestBehavior.opaque,
                    child: badge,
                  ),
                ),
              ),
            );
          },
        );
      } else {
        final activate = onTap ?? () => launchArchiveDetails(text, context);
        badgeWithTap = Semantics(
          button: true,
          label: semanticLabel,
          child: ExcludeSemantics(
            child: FocusableActionDetector(
              enabled: true,
              mouseCursor: SystemMouseCursors.click,
              shortcuts: const <ShortcutActivator, Intent>{
                SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              },
              actions: <Type, Action<Intent>>{
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    activate();
                    return null;
                  },
                ),
              },
              child: GestureDetector(
                onTap: activate,
                behavior: HitTestBehavior.opaque,
                child: badge,
              ),
            ),
          ),
        );
      }
    }

    if (useNeumorphic) {
      return NeumorphicWrapper(
        isCircle: false,
        borderRadius: 10.0,
        intensity: 0.9,
        color: Colors.transparent,
        child: LiquidGlassWrapper(
          enabled: true,
          borderRadius: BorderRadius.circular(10.0),
          opacity: 0.08,
          blur: 5.0,
          child: badgeWithTap,
        ),
      );
    }

    return badgeWithTap;
  }
}
