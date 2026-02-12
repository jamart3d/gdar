import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';

class TvListTile extends StatelessWidget {
  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  final VisualDensity? visualDensity;
  final EdgeInsetsGeometry? contentPadding;

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
  });

  @override
  Widget build(BuildContext context) {
    final isTv = context.read<DeviceService>().isTv;

    if (isTv) {
      return TvFocusWrapper(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
            contentPadding: contentPadding ??
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
