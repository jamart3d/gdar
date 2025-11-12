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
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use a TextPainter to determine if the text will overflow
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: double.infinity);

        // If the text width is greater than the available width, show Marquee
        if (textPainter.width > constraints.maxWidth) {
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
          return SizedBox(
            width: double.infinity,
            child: Text(
              text,
              style: style,
              textAlign: textAlign,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }
      },
    );
  }
}
