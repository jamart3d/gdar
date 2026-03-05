import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown/ui/widgets/theme/liquid_glass_wrapper.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final IconData? lucideIcon;
  final List<Widget> children;
  final bool initiallyExpanded;
  final bool collapsible;
  final double scaleFactor;
  final VoidCallback? onTap;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
    this.collapsible = true,
    this.scaleFactor = 1.0,
    this.lucideIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (context.read<DeviceService>().isTv) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Row(
              children: [
                Icon(icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28 * scaleFactor),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 28 * scaleFactor,
                      ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      );
    }

    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final useNeumorphism = settingsProvider.useNeumorphism;
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    final activeIcon = (isFruit && lucideIcon != null) ? lucideIcon! : icon;

    final colorScheme = Theme.of(context).colorScheme;

    Widget content = Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
      ),
      child: onTap != null
          ? ListTile(
              onTap: onTap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              leading: Icon(activeIcon,
                  color: colorScheme.primary, size: 24 * scaleFactor),
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize:
                            (Theme.of(context).textTheme.titleLarge?.fontSize ??
                                    22.0) *
                                scaleFactor,
                      ),
                ),
              ),
              trailing: Icon(
                  isFruit ? LucideIcons.chevronRight : Icons.chevron_right,
                  color: colorScheme.primary,
                  size: 24 * scaleFactor),
            )
          : collapsible
              ? ExpansionTile(
                  initiallyExpanded: initiallyExpanded,
                  maintainState: true,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  leading: Icon(activeIcon,
                      color: colorScheme.primary, size: 24 * scaleFactor),
                  title: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: (Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.fontSize ??
                                    22.0) *
                                scaleFactor,
                          ),
                    ),
                  ),
                  children: children,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        children: [
                          Icon(activeIcon,
                              color: colorScheme.primary,
                              size: 24 * scaleFactor),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: (Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.fontSize ??
                                              22.0) *
                                          scaleFactor,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...children,
                    const SizedBox(height: 8.0),
                  ],
                ),
    );

    if (useNeumorphism) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: NeumorphicWrapper(
          borderRadius: 28,
          child: LiquidGlassWrapper(
            enabled: isFruit && settingsProvider.fruitEnableLiquidGlass,
            borderRadius: BorderRadius.circular(28),
            child: content,
          ),
        ),
      );
    }

    final useTrueBlack = settingsProvider.useTrueBlack;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      color: (useTrueBlack && isDark)
          ? Colors.transparent
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: (useTrueBlack && isDark)
            ? BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2), width: 0.5)
            : BorderSide.none,
      ),
      child: content,
    );
  }
}
