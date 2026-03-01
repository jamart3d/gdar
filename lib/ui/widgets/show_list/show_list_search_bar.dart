import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown/providers/theme_provider.dart';

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
    final settingsProvider = context.watch<SettingsProvider>();
    final isSearchVisible = context.watch<ShowListProvider>().isSearchVisible;

    Widget searchBar = SearchBar(
      controller: controller,
      focusNode: focusNode,
      hintText: 'Search venue, date, location — or paste to play',
      leading: const Icon(Icons.search_rounded),
      trailing: controller.text.isNotEmpty
          ? [
              IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () => controller.clear())
            ]
          : [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.content_paste_rounded,
                  size: 20,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.5),
                ),
              ),
            ],
      onSubmitted: onSubmitted,
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      )),
    );

    if (context.watch<DeviceService>().isTv) {
      searchBar = TvFocusWrapper(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          focusNode.requestFocus();
        },
        child: searchBar,
      );
    }

    // Apply Neumorphism if enabled and in Fruit style
    final isFruitStyle =
        context.watch<ThemeProvider>().themeStyle == ThemeStyle.fruit;
    final useNeumorphism = settingsProvider.useNeumorphism &&
        isFruitStyle &&
        !settingsProvider.useTrueBlack;

    if (useNeumorphism) {
      searchBar = SearchBar(
        controller: controller,
        focusNode: focusNode,
        hintText: 'Search venue, date, location — or paste to play',
        leading: const Icon(Icons.search_rounded),
        trailing: controller.text.isNotEmpty
            ? [
                IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () => controller.clear())
              ]
            : [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.content_paste_rounded,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.5),
                  ),
                ),
              ],
        onSubmitted: onSubmitted,
        elevation: const WidgetStatePropertyAll(0),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide.none, // Removed for Neumorphism
        )),
      );

      searchBar = LiquidGlassWrapper(
        enabled: true,
        borderRadius: BorderRadius.circular(28),
        opacity: 0.1, // Subtle glass effect for the search bar basin
        blur: 8,
        child: NeumorphicWrapper(
          borderRadius: 28,
          style: NeumorphicStyle.concave,
          intensity: 0.85, // Refined intensity
          child: searchBar,
        ),
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
