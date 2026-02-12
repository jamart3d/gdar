import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';

class TvRadioListTile<T> extends StatelessWidget {
  final Widget? title;
  final Widget? subtitle;
  final T value;
  final bool dense;
  final Widget? secondary;

  const TvRadioListTile({
    super.key,
    this.title,
    this.subtitle,
    required this.value,
    this.dense = false,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    if (context.read<DeviceService>().isTv) {
      return TvFocusWrapper(
        onTap: () {
          // If we are under a RadioGroup, we can't easily call onChanged here
          // unless we find the RadioGroup state.
          // However, RadioListTile handles its own internal tap if not ignored.
          // Since we use IgnorePointer, we need to trigger the change.
          // RadioGroup usually provides a way to change value.
        },
        borderRadius: BorderRadius.circular(12),
        child: IgnorePointer(
          ignoring: true,
          child: RadioListTile<T>(
            title: title,
            subtitle: subtitle,
            value: value,
            dense: dense,
            secondary: secondary,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
        ),
      );
    }

    return RadioListTile<T>(
      title: title,
      subtitle: subtitle,
      value: value,
      dense: dense,
      secondary: secondary,
    );
  }
}
