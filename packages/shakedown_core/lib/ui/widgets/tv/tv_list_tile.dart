import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';

class TvListTile extends StatelessWidget {
  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  final VisualDensity? visualDensity;
  final EdgeInsetsGeometry? contentPadding;
  final bool autofocus;
  final bool useRgbBorder;

  const TvListTile({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.visualDensity,
    this.contentPadding,
    this.autofocus = false,
    this.useRgbBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTv = context.read<DeviceService>().isTv;

    if (isTv) {
      return TvFocusWrapper(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        autofocus: autofocus,
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
        child: IgnorePointer(
          ignoring: true,
          child: ListTile(
            title: title,
            subtitle: subtitle,
            leading: leading,
            trailing: trailing,
            onTap: onTap,
            dense: dense,
            visualDensity: visualDensity,
            contentPadding:
                contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
        ),
      );
    }

    return ListTile(
      title: title,
      subtitle: subtitle,
      leading: leading,
      trailing: trailing,
      onTap: onTap,
      dense: dense,
      visualDensity: visualDensity,
      contentPadding: contentPadding,
    );
  }
}
