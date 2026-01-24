import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

/// A widget that displays a scrolling [Marquee] if the text overflows its
/// container, otherwise displays a standard [Text] widget.
class ConditionalMarquee extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final double velocity;
  final Duration pauseAfterRound;
  final double blankSpace;
  final double fadingEdgeStartFraction;
  final double fadingEdgeEndFraction;
  final bool enableAnimation;

  const ConditionalMarquee({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.velocity = 30.0,
    this.pauseAfterRound = const Duration(seconds: 2),
    this.blankSpace = 40.0,
    this.fadingEdgeStartFraction = 0.1,
    this.fadingEdgeEndFraction = 0.1,
    this.enableAnimation = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!enableAnimation) {
          return Text(
            text,
            style: style,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        // Use a TextPainter to determine if the text will overflow
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: double.infinity);

        // If the text width is greater than the available width (minus a safety buffer), show Marquee
        // Safety buffer prevents cases where TextPainter under-reports width slightly compared to render.
        // Increased to 50.0 for Rock Salt's aggressive sizing and wide flourishes.
        if (textPainter.width > constraints.maxWidth - 50.0) {
          return ClipRect(
            child: Marquee(
              text: text,
              style: style,
              velocity: velocity,
              pauseAfterRound: pauseAfterRound,
              blankSpace: blankSpace,
              fadingEdgeStartFraction: fadingEdgeStartFraction,
              fadingEdgeEndFraction: fadingEdgeEndFraction,
            ),
          );
        } else {
          // Otherwise, show a standard Text widget
          return Text(
            text,
            style: style,
            textAlign: textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
      },
    );
  }
}
