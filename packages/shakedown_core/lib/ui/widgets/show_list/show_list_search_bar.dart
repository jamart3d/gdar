import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_ui.dart';

import 'package:lucide_icons/lucide_icons.dart';

class ShowListSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final Duration animationDuration;

  const ShowListSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final isFruitStyle = tp.themeStyle == ThemeStyle.fruit;
    final settingsProvider = context.watch<SettingsProvider>();
    final isSearchVisible = context.watch<ShowListProvider>().isSearchVisible;

    Widget searchBar;

    if (isFruitStyle) {
      // Fruit Search Basin: never fallback to Material widgets in Fruit mode.
      searchBar = ListenableBuilder(
        listenable: focusNode,
        builder: (context, child) {
          final hasFocus = focusNode.hasFocus;
          final primaryColor = Theme.of(context).colorScheme.primary;

          return FruitSurface(
            borderRadius: BorderRadius.circular(FruitTokens.radiusLarge),
            blur: FruitTokens.blurStrong,
            opacity: 0.65,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(FruitTokens.radiusLarge),
                border: Border.all(
                  color: hasFocus
                      ? primaryColor.withValues(alpha: 0.5)
                      : const Color(0x00000000),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.search,
                      size: 18,
                      color: hasFocus
                          ? primaryColor
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onSubmitted: onSubmitted,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Search venue, date, location...',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.38),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (controller.text.isNotEmpty)
                      GestureDetector(
                        onTap: controller.clear,
                        child: Icon(
                          LucideIcons.xCircle,
                          size: 18,
                          color: hasFocus
                              ? primaryColor.withValues(alpha: 0.7)
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      // Standard Material 3 SearchBar fallback
      searchBar = SearchBar(
        controller: controller,
        focusNode: focusNode,
        hintText: 'Search venue, date, location — or paste to play',
        leading: const Icon(Icons.search_rounded),
        trailing: controller.text.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => controller.clear(),
                ),
              ]
            : [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.content_paste_rounded,
                    size: 20,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ],
        onSubmitted: onSubmitted,
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
      );
    }

    if (context.watch<DeviceService>().isTv) {
      searchBar = TvFocusWrapper(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          focusNode.requestFocus();
        },
        child: searchBar,
      );
    }

    return AnimatedSize(
      duration: animationDuration,
      curve: Curves.easeInOutCubicEmphasized,
      child: isSearchVisible
          ? Transform.scale(
              scale: settingsProvider.uiScale ? 1.1 : 1.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: searchBar,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
