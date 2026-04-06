import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/ui/styles/app_typography.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/ui/widgets/rating_stars.dart';

class RatingControl extends StatelessWidget {
  final int rating;
  final VoidCallback? onTap;
  final double size;
  final bool isPlayed;
  final bool compact;
  final bool enforceMinTapTarget;

  const RatingControl({
    super.key,
    required this.rating,
    this.onTap,
    this.size = 24.0,
    this.isPlayed = false,
    this.compact = false,
    this.enforceMinTapTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    final scaledSize = AppTypography.responsiveFontSize(context, size);

    final Widget content = RatingStars(
      rating: rating,
      size: size,
      isPlayed: isPlayed,
      compact: compact,
    );

    if (onTap == null) {
      return content;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppHaptics.selectionClick(context.read<DeviceService>());
        onTap!();
      },
      child: compact
          ? content // No wrapping/padding for compact layouts
          : (enforceMinTapTarget
                ? ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: ((scaledSize * 1.35).clamp(
                        40.0,
                        48.0,
                      )).toDouble(),
                      minHeight: ((scaledSize * 1.35).clamp(
                        40.0,
                        48.0,
                      )).toDouble(),
                    ),
                    child: Center(child: content),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    child: Center(child: content),
                  )),
    );
  }
}
