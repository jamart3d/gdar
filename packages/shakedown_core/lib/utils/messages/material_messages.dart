import 'package:flutter/material.dart';

void showMaterialSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
  );
}

void showMaterialSnackBarWithAction(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            Icons.refresh_rounded,
            color: Theme.of(context).colorScheme.primaryContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
      duration: const Duration(seconds: 10),
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
              textColor: Theme.of(context).colorScheme.primary,
            )
          : null,
    ),
  );
}
