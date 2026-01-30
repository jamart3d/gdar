import 'package:flutter/material.dart';
import 'package:shakedown/ui/widgets/onboarding/onboarding_components.dart';
import 'package:shakedown/ui/widgets/show_list/animated_dice_icon.dart';

class TipsPage extends StatelessWidget {
  final double scaleFactor;

  const TipsPage({super.key, required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
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
              OnboardingComponents.buildSectionHeader(
                  context, 'Quick Tips', scaleFactor),
              const SizedBox(height: 20),
              OnboardingComponents.buildTipRow(
                  context,
                  OnboardingComponents.buildIconBubble(
                      context, Icons.touch_app_rounded),
                  'Long press a show card for playing, single tap track play is off by default',
                  scaleFactor),
              const SizedBox(height: 16),
              OnboardingComponents.buildTipRow(
                  context,
                  SizedBox(
                    width: 28 * scaleFactor,
                    height: 28 * scaleFactor,
                    child: FittedBox(
                      child: AnimatedDiceIcon(
                        onPressed: () {},
                        isLoading: false,
                        changeFaces: false,
                      ),
                    ),
                  ),
                  'Tap to randomly select and discover a show you may not have heard',
                  scaleFactor),
              const SizedBox(height: 16),
              OnboardingComponents.buildTipRow(
                  context,
                  OnboardingComponents.buildIconBubble(
                      context, Icons.star_rate_rounded),
                  'Rate shows for random selection to use',
                  scaleFactor),
              const SizedBox(height: 16),
              OnboardingComponents.buildTipRow(
                  context,
                  OnboardingComponents.buildIconBubble(
                      context, Icons.settings_rounded),
                  'Check out the settings for more options and usage instructions',
                  scaleFactor),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    });
  }
}
