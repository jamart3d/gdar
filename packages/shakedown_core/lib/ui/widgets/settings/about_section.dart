import 'package:flutter/material.dart';
import 'package:shakedown_core/ui/screens/about_screen.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown_core/ui/widgets/section_card.dart';
import 'package:shakedown_core/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/ui/widgets/pulsing_heart_icon.dart';

class SupportSection extends StatelessWidget {
  final double scaleFactor;

  const SupportSection({super.key, required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    return SectionCard(
      scaleFactor: scaleFactor,
      title: 'Support & Donate',
      icon: Icons.favorite_border_rounded,
      lucideIcon: LucideIcons.heart,
      initiallyExpanded: true,
      collapsible: false,
      showHeader: false,
      children: [
        _buildClickableLink(
          context,
          'Consider donating to The Internet Archive',
          'https://archive.org/donate/',
          scaleFactor,
          customIcon: PulsingHeartIcon(
            scaleFactor: scaleFactor,
            isFruit: isFruit,
          ),
        ),
      ],
    );
  }

  Widget _buildClickableLink(
    BuildContext context,
    String text,
    String url,
    double scaleFactor, {
    IconData? icon,
    Widget? customIcon,
  }) {
    final isFruit =
        context.read<ThemeProvider>().themeStyle == ThemeStyle.fruit;
    return TvFocusWrapper(
      onTap: () => launchExternalUrl(url, context),
      borderRadius: BorderRadius.circular(12),
      focusDecoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      showGlow: false,
      useRgbBorder: true,
      tightDecorativeBorder: true,
      decorativeBorderGap: 1.0,
      overridePremiumHighlight: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (customIcon != null) ...[
              customIcon,
              const SizedBox(width: 12),
            ] else if (icon != null) ...[
              Icon(icon, size: 20 * scaleFactor, color: Colors.pinkAccent),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                  fontSize: 14 * scaleFactor,
                ),
              ),
            ),
            Icon(
              isFruit ? LucideIcons.externalLink : Icons.open_in_new,
              size: 16 * scaleFactor,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class AboutSection extends StatelessWidget {
  final double scaleFactor;

  const AboutSection({super.key, required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      scaleFactor: scaleFactor,
      title: 'About App',
      icon: Icons.info_outline,
      lucideIcon: LucideIcons.info,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutScreen()),
        );
      },
      children: const [],
    );
  }
}
