import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/link.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:shakedown_core/utils/utils.dart';

class ShnidBadge extends StatelessWidget {
  final String text;
  final bool showUnderline;
  final double scaleFactor;
  final VoidCallback? onTap;
  final bool interactive;
  final Uri? uri;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;
  final double? maxWidth;
  final FontWeight? fontWeight;

  const ShnidBadge({
    super.key,
    required this.text,
    this.showUnderline = false,
    this.scaleFactor = 1.0,
    this.onTap,
    this.interactive = true,
    this.uri,
    this.fontSize,
    this.padding,
    this.maxWidth,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final isTv = context.watch<DeviceService>().isTv;
    if (isTv || text.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final double effectiveScale = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    final List<Color> gradientColors = isTrueBlackMode
        ? [Colors.black, Colors.black]
        : [
            colorScheme.secondaryContainer.withValues(alpha: 0.7),
            colorScheme.secondaryContainer.withValues(alpha: 0.5),
          ];

    final textColor = colorScheme.onSecondaryContainer;

    Widget content = Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: textColor,
        fontWeight: fontWeight ?? FontWeight.w600,
        fontSize:
            (fontSize ??
                ((settingsProvider.appFont == 'rock_salt')
                    ? 7.5 * effectiveScale
                    : 9.0 * effectiveScale)) *
            scaleFactor,
        height: (settingsProvider.appFont == 'rock_salt') ? 2.0 : 1.5,
        letterSpacing:
            (settingsProvider.appFont == 'rock_salt' ||
                settingsProvider.appFont == 'permanent_marker')
            ? 1.5 * scaleFactor
            : 0.0,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textAlign: TextAlign.center,
    );

    if (showUnderline) {
      content = Container(
        padding: const EdgeInsets.only(bottom: 2.5),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: textColor.withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
        ),
        child: content,
      );
    }

    Widget badge = Container(
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: 6 * scaleFactor,
            vertical: 1.0 * scaleFactor,
          ),
      constraints: maxWidth == null
          ? null
          : BoxConstraints(maxWidth: maxWidth! * scaleFactor),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: content,
    );

    if (!interactive) return badge;

    final semanticLabel = 'Open archive details for $text';
    final activate = onTap ?? () => launchArchiveDetails(text, context);

    if (uri != null) {
      return Link(
        uri: uri,
        target: LinkTarget.blank,
        builder: (context, followLink) {
          final linkActivate = followLink ?? activate;
          return _wrapWithFocus(context, badge, linkActivate, semanticLabel);
        },
      );
    }

    return _wrapWithFocus(context, badge, activate, semanticLabel);
  }

  Widget _wrapWithFocus(
    BuildContext context,
    Widget child,
    VoidCallback onTap,
    String label,
  ) {
    return Semantics(
      button: true,
      label: label,
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
                onTap();
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: child,
          ),
        ),
      ),
    );
  }
}
