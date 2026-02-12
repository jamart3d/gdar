import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/ui/screens/about_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shakedown/ui/widgets/tv/tv_list_tile.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';

class AboutSection extends StatelessWidget {
  final double scaleFactor;

  const AboutSection({
    super.key,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.3),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          TvListTile(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const AboutScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = 0.92;
                    const end = 1.0;
                    const curve = Curves.easeOutCubic;

                    var scaleTween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    var fadeTween = Tween(begin: 0.0, end: 1.0)
                        .chain(CurveTween(curve: curve));

                    return FadeTransition(
                      opacity: animation.drive(fadeTween),
                      child: ScaleTransition(
                        scale: animation.drive(scaleTween),
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                  reverseTransitionDuration: const Duration(milliseconds: 350),
                ),
              );
            },
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(Icons.info_outline,
                color: Theme.of(context).colorScheme.primary),
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'About App',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * scaleFactor),
              ),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
          ),
          _buildClickableLink(
            context,
            'Consider donating to The Internet Archive',
            'https://archive.org/donate/',
            scaleFactor,
            customIcon: _PulsingHeartIcon(scaleFactor: scaleFactor),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableLink(
      BuildContext context, String text, String url, double scaleFactor,
      {IconData? icon, Widget? customIcon}) {
    // For now, implementing locally as it was private in SettingsScreen
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
            Icon(Icons.open_in_new,
                size: 16 * scaleFactor,
                color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }
}

class _PulsingHeartIcon extends StatefulWidget {
  final double scaleFactor;

  const _PulsingHeartIcon({required this.scaleFactor});

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
        Icons.favorite,
        size: 20 * widget.scaleFactor,
        color: Colors.pinkAccent,
      ),
    );
  }
}
