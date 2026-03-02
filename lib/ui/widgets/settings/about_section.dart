import 'package:flutter/material.dart';
import 'package:shakedown/ui/screens/about_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown/ui/widgets/section_card.dart';
import 'package:provider/provider.dart';

class SupportSection extends StatelessWidget {
  final double scaleFactor;

  const SupportSection({
    super.key,
    required this.scaleFactor,
  });

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
      children: [
        _buildClickableLink(
          context,
          'Consider donating to The Internet Archive',
          'https://archive.org/donate/',
          scaleFactor,
          customIcon:
              _PulsingHeartIcon(scaleFactor: scaleFactor, isFruit: isFruit),
        ),
      ],
    );
  }

  Widget _buildClickableLink(
      BuildContext context, String text, String url, double scaleFactor,
      {IconData? icon, Widget? customIcon}) {
    final isFruit =
        context.read<ThemeProvider>().themeStyle == ThemeStyle.fruit;
    return TvFocusWrapper(
      onTap: () => _launchUrl(context, url),
      borderRadius: BorderRadius.circular(12),
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
            Icon(isFruit ? LucideIcons.externalLink : Icons.open_in_new,
                size: 16 * scaleFactor,
                color: Theme.of(context).colorScheme.primary),
          ],
        ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open browser: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class AboutSection extends StatelessWidget {
  final double scaleFactor;

  const AboutSection({
    super.key,
    required this.scaleFactor,
  });

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

class _PulsingHeartIcon extends StatefulWidget {
  final double scaleFactor;
  final bool isFruit;

  const _PulsingHeartIcon({required this.scaleFactor, required this.isFruit});

  @override
  State<_PulsingHeartIcon> createState() => _PulsingHeartIconState();
}

class _PulsingHeartIconState extends State<_PulsingHeartIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 2), // Pause
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Icon(
        widget.isFruit ? LucideIcons.heart : Icons.favorite,
        size: 20 * widget.scaleFactor,
        color: Colors.pinkAccent,
      ),
    );
  }
}
