part of 'appearance_section.dart';

extension _AppearanceSectionControls on _AppearanceSectionState {
  Widget _buildThemeModeSection(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    if (context.watch<DeviceService>().isTv) {
      return TvSwitchListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        title: _buildTileTitle(context, 'Dark'),
        value: themeProvider.isDarkMode,
        onChanged: (value) {
          AppHaptics.lightImpact(context.read<DeviceService>());
          context.read<ThemeProvider>().setThemeMode(
            value ? ThemeMode.dark : ThemeMode.light,
          );
        },
        secondary: Icon(
          themeProvider.themeStyle == ThemeStyle.fruit
              ? (themeProvider.isDarkMode ? LucideIcons.moon : LucideIcons.sun)
              : (themeProvider.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 16.0 * widget.scaleFactor,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return TvFocusWrapper(
                borderRadius: BorderRadius.circular(isFruit ? 28 : 24),
                child: SingleChildScrollView(
                  key: const PageStorageKey('appearance_theme_scroll'),
                  controller: ScrollController(keepScrollOffset: false),
                  scrollDirection: Axis.horizontal,
                  child: themeProvider.themeStyle == ThemeStyle.fruit
                      ? FruitSegmentedControl<ThemeMode>(
                          values: ThemeMode.values,
                          selectedValue: themeProvider.selectedThemeMode,
                          onSelectionChanged: (newMode) {
                            _handleThemeModeChanged(context, newMode);
                          },
                          labelBuilder: (mode) {
                            late final IconData icon;
                            switch (mode) {
                              case ThemeMode.system:
                                icon = LucideIcons.monitor;
                              case ThemeMode.light:
                                icon = LucideIcons.sun;
                              case ThemeMode.dark:
                                icon = LucideIcons.moon;
                            }
                            return Icon(icon, size: 20);
                          },
                        )
                      : SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(
                                themeProvider.themeStyle == ThemeStyle.fruit
                                    ? LucideIcons.monitor
                                    : Icons.brightness_auto_rounded,
                              ),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(
                                themeProvider.themeStyle == ThemeStyle.fruit
                                    ? LucideIcons.sun
                                    : Icons.light_mode_rounded,
                              ),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(
                                themeProvider.themeStyle == ThemeStyle.fruit
                                    ? LucideIcons.moon
                                    : Icons.dark_mode_rounded,
                              ),
                            ),
                          ],
                          selected: {themeProvider.selectedThemeMode},
                          onSelectionChanged: (Set<ThemeMode> newSelection) {
                            _handleThemeModeChanged(
                              context,
                              newSelection.first,
                            );
                          },
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isFruit ? 28 : 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeStyleSection(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Style',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 16.0 * widget.scaleFactor,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return TvFocusWrapper(
                borderRadius: BorderRadius.circular(isFruit ? 28 : 24),
                child: SingleChildScrollView(
                  key: const PageStorageKey('appearance_style_scroll'),
                  controller: ScrollController(keepScrollOffset: false),
                  scrollDirection: Axis.horizontal,
                  child: themeProvider.themeStyle == ThemeStyle.fruit
                      ? FruitSegmentedControl<ThemeStyle>(
                          values: themeProvider.isFruitAllowed
                              ? ThemeStyle.values
                              : [ThemeStyle.android],
                          selectedValue: themeProvider.themeStyle,
                          onSelectionChanged: (style) {
                            _handleThemeStyleChanged(context, style);
                          },
                          labelBuilder: (style) {
                            late final IconData icon;
                            switch (style) {
                              case ThemeStyle.android:
                                icon =
                                    themeProvider.themeStyle == ThemeStyle.fruit
                                    ? LucideIcons.bot
                                    : Icons.smart_toy_rounded;
                              case ThemeStyle.fruit:
                                icon =
                                    themeProvider.themeStyle == ThemeStyle.fruit
                                    ? LucideIcons.apple
                                    : Icons.apple_rounded;
                            }
                            return Icon(icon, size: 20);
                          },
                        )
                      : SegmentedButton<ThemeStyle>(
                          segments: [
                            ButtonSegment(
                              value: ThemeStyle.android,
                              icon: Icon(
                                themeProvider.themeStyle == ThemeStyle.fruit
                                    ? LucideIcons.bot
                                    : Icons.smart_toy_rounded,
                              ),
                            ),
                            ButtonSegment(
                              value: ThemeStyle.fruit,
                              icon: Icon(
                                themeProvider.themeStyle == ThemeStyle.fruit
                                    ? LucideIcons.apple
                                    : Icons.apple_rounded,
                              ),
                            ),
                          ],
                          selected: {themeProvider.themeStyle},
                          onSelectionChanged: (Set<ThemeStyle> newSelection) {
                            _handleThemeStyleChanged(
                              context,
                              newSelection.first,
                            );
                          },
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isFruit ? 28 : 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFruitOptionsSwitcher(
    BuildContext context,
    ThemeProvider themeProvider,
    SettingsProvider settingsProvider,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1.0,
            child: child,
          ),
        );
      },
      child: themeProvider.themeStyle == ThemeStyle.fruit
          ? Column(
              key: const ValueKey('fruit_options_group'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accent Color',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16.0 * widget.scaleFactor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FruitSegmentedControl<FruitColorOption>(
                        values: FruitColorOption.values,
                        selectedValue: themeProvider.fruitColorOption,
                        onSelectionChanged: (option) {
                          AppHaptics.lightImpact(context.read<DeviceService>());
                          themeProvider.setFruitColorOption(option);
                        },
                        labelBuilder: (option) {
                          late final IconData icon;
                          switch (option) {
                            case FruitColorOption.sophisticate:
                              icon = LucideIcons.moon;
                            case FruitColorOption.minimalist:
                              icon = LucideIcons.sun;
                            case FruitColorOption.creative:
                              icon = LucideIcons.palette;
                          }
                          return Icon(icon, size: 20);
                        },
                      ),
                    ],
                  ),
                ),
                TvSwitchListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: _buildTileTitle(context, 'Dense Show List'),
                  subtitle: _buildTileSubtitle(
                    context,
                    'Shows more items on screen with tighter spacing',
                  ),
                  value: settingsProvider.fruitDenseList,
                  onChanged: (value) {
                    AppHaptics.lightImpact(context.read<DeviceService>());
                    context.read<SettingsProvider>().toggleFruitDenseList();
                  },
                  secondary: const Icon(LucideIcons.listFilter),
                ),
                TvSwitchListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: _buildTileTitle(context, 'Liquid Glass'),
                  subtitle: _buildTileSubtitle(
                    context,
                    'Off switches Fruit into Simple Theme for lighter rendering',
                  ),
                  value:
                      !settingsProvider.performanceMode &&
                      settingsProvider.fruitEnableLiquidGlass,
                  onChanged: (value) {
                    AppHaptics.lightImpact(context.read<DeviceService>());
                    final provider = context.read<SettingsProvider>();
                    if (value) {
                      provider.setPerformanceMode(false);
                      provider.setFruitEnableLiquidGlass(true);
                    } else {
                      provider.setFruitEnableLiquidGlass(false);
                      provider.setPerformanceMode(true);
                    }
                  },
                  secondary: const Icon(LucideIcons.droplet),
                ),
                TvSwitchListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: _buildTileTitle(context, 'Highlight Playing with RGB'),
                  subtitle: _buildTileSubtitle(
                    context,
                    'Animate border with RGB colors',
                  ),
                  value: settingsProvider.highlightPlayingWithRgb,
                  onChanged: (value) {
                    AppHaptics.lightImpact(context.read<DeviceService>());
                    context
                        .read<SettingsProvider>()
                        .toggleHighlightPlayingWithRgb();
                  },
                  secondary: const Icon(LucideIcons.zap),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildPerformanceModeTile(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return TvSwitchListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: _buildTileTitle(context, 'Performance Mode (Simple Theme)'),
      subtitle: _buildTileSubtitle(
        context,
        'Optimizes UI for older phones (removes blurs, shadows, and complex animations)',
      ),
      value: settingsProvider.performanceMode,
      onChanged: (value) {
        AppHaptics.lightImpact(context.read<DeviceService>());
        context.read<SettingsProvider>().togglePerformanceMode();
      },
      secondary: const Icon(LucideIcons.zap),
    );
  }

  Widget _buildDynamicColorTile(
    BuildContext context,
    SettingsProvider settingsProvider,
    ThemeProvider themeProvider,
  ) {
    return TvSwitchListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: _buildTileTitle(context, 'Dynamic Color'),
      subtitle: _buildTileSubtitle(context, 'Theme from wallpaper'),
      value: settingsProvider.useDynamicColor,
      onChanged: (value) {
        AppHaptics.lightImpact(context.read<DeviceService>());
        context.read<SettingsProvider>().toggleUseDynamicColor();
      },
      secondary: Icon(
        themeProvider.themeStyle == ThemeStyle.fruit
            ? LucideIcons.palette
            : Icons.color_lens_rounded,
      ),
    );
  }

  Widget _buildTrueBlackTile(
    BuildContext context,
    SettingsProvider settingsProvider,
    ThemeProvider themeProvider,
  ) {
    return TvSwitchListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: _buildTileTitle(context, 'True Black'),
      subtitle: _buildTileSubtitle(context, 'Shadows and blur disabled'),
      value: settingsProvider.useTrueBlack,
      onChanged: (value) {
        AppHaptics.lightImpact(context.read<DeviceService>());
        context.read<SettingsProvider>().toggleUseTrueBlack();
      },
      secondary: Icon(
        themeProvider.themeStyle == ThemeStyle.fruit
            ? LucideIcons.circle
            : Icons.brightness_1_rounded,
      ),
    );
  }

  Widget _buildCustomThemeColorControl(
    BuildContext context,
    SettingsProvider settingsProvider,
    ThemeProvider themeProvider,
  ) {
    if (context.watch<DeviceService>().isTv) {
      return RainbowColorPicker(scaleFactor: widget.scaleFactor);
    }

    final colorScheme = Theme.of(context).colorScheme;
    return TvListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(
        themeProvider.themeStyle == ThemeStyle.fruit
            ? LucideIcons.palette
            : Icons.palette_rounded,
      ),
      title: _buildTileTitle(context, 'Custom Theme Color'),
      subtitle: _buildTileSubtitle(
        context,
        'Overrides the default theme color',
      ),
      onTap: () => ColorPickerDialog.show(context),
      trailing: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: settingsProvider.seedColor ?? Colors.purple,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outline, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildGlowBorderTile(
    BuildContext context,
    SettingsProvider settingsProvider,
    ThemeProvider themeProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isGated = settingsProvider.performanceMode;
    const reason = 'Disabled in Simple Theme';

    return TvSwitchListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          'Glow Border',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 16 * widget.scaleFactor,
            color: isGated
                ? colorScheme.onSurface.withValues(alpha: 0.5)
                : null,
          ),
        ),
      ),
      subtitle: isGated
          ? Text(
              reason,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12 * widget.scaleFactor,
                color: colorScheme.secondary.withValues(alpha: 0.7),
              ),
            )
          : null,
      value: !isGated && settingsProvider.glowMode > 0,
      onChanged: isGated
          ? null
          : (value) {
              context.read<SettingsProvider>().setGlowMode(value ? 65 : 0);
            },
      secondary: Icon(
        themeProvider.themeStyle == ThemeStyle.fruit
            ? LucideIcons.sparkles
            : Icons.blur_on_rounded,
        color: isGated ? colorScheme.onSurface.withValues(alpha: 0.3) : null,
      ),
    );
  }

  Widget _buildGlowIntensityControl(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Text(
                  'Intensity',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12.0 * widget.scaleFactor,
                  ),
                ),
                Expanded(
                  child: TvFocusWrapper(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                          final newValue = (settingsProvider.glowMode - 5)
                              .clamp(10, 100);
                          if (newValue != settingsProvider.glowMode) {
                            AppHaptics.selectionClick(
                              context.read<DeviceService>(),
                            );
                            context.read<SettingsProvider>().setGlowMode(
                              newValue,
                            );
                          }
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                          final newValue = (settingsProvider.glowMode + 5)
                              .clamp(10, 100);
                          if (newValue != settingsProvider.glowMode) {
                            AppHaptics.selectionClick(
                              context.read<DeviceService>(),
                            );
                            context.read<SettingsProvider>().setGlowMode(
                              newValue,
                            );
                          }
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    borderRadius: BorderRadius.circular(12),
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
                    child: Slider(
                      onChangeStart: (_) =>
                          AppHaptics.lightImpact(context.read<DeviceService>()),
                      value: settingsProvider.glowMode.toDouble(),
                      min: 10,
                      max: 100,
                      divisions: 18,
                      label: '${settingsProvider.glowMode}%',
                      onChanged: (value) {
                        if (value.round() != settingsProvider.glowMode) {
                          AppHaptics.selectionClick(
                            context.read<DeviceService>(),
                          );
                        }
                        context.read<SettingsProvider>().setGlowMode(
                          value.round(),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 40 * widget.scaleFactor,
                  child: Text(
                    '${settingsProvider.glowMode}%',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 12.0 * widget.scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightPlayingTile(
    BuildContext context,
    SettingsProvider settingsProvider,
    ThemeProvider themeProvider,
  ) {
    return TvSwitchListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          'Highlight Playing with RGB',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontSize: 16 * widget.scaleFactor),
        ),
      ),
      subtitle: _buildTileSubtitle(
        context,
        'Animate active border with RGB colors, including in Simple Theme',
      ),
      value: settingsProvider.highlightPlayingWithRgb,
      onChanged: (value) {
        final provider = context.read<SettingsProvider>();
        provider.toggleHighlightPlayingWithRgb();
        if (!value && provider.useTrueBlack) {
          provider.setGlowMode(0);
        }
      },
      secondary: Icon(
        themeProvider.themeStyle == ThemeStyle.fruit
            ? LucideIcons.zap
            : Icons.animation_rounded,
      ),
    );
  }

  Widget _buildRgbAnimationSpeedControl(
    BuildContext context,
    SettingsProvider settingsProvider,
    ThemeProvider themeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RGB Animation Speed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12.0 * widget.scaleFactor,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedGradientBorder(
            borderRadius: 24,
            borderWidth: 3,
            allowInPerformanceMode: true,
            colors: const [
              Colors.red,
              Colors.yellow,
              Colors.green,
              Colors.cyan,
              Colors.blue,
              Colors.purple,
              Colors.red,
            ],
            enabled: true,
            showShadow: true,
            glowOpacity: 0.5 * (settingsProvider.glowMode / 100.0),
            animationSpeed: settingsProvider.rgbAnimationSpeed,
            ignoreGlobalClock: true,
            backgroundColor: Colors.transparent,
            child: TvFocusWrapper(
              borderRadius: BorderRadius.circular(21),
              focusDecoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(21),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              showGlow: false,
              useRgbBorder: false,
              tightDecorativeBorder: true,
              decorativeBorderGap: 1.0,
              overridePremiumHighlight: false,
              child: SingleChildScrollView(
                key: const PageStorageKey('rgb_speed_scroll'),
                controller: ScrollController(keepScrollOffset: false),
                scrollDirection: Axis.horizontal,
                child: themeProvider.themeStyle == ThemeStyle.fruit
                    ? FruitSegmentedControl<double>(
                        values: const [1.0, 0.5, 0.25, 0.1],
                        selectedValue: settingsProvider.rgbAnimationSpeed,
                        onSelectionChanged: (value) {
                          AppHaptics.lightImpact(context.read<DeviceService>());
                          context.read<SettingsProvider>().setRgbAnimationSpeed(
                            value,
                          );
                        },
                        labelBuilder: (value) {
                          if (value == 1.0) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.zap, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Fast',
                                  style: TextStyle(
                                    fontSize: 12 * widget.scaleFactor,
                                  ),
                                ),
                              ],
                            );
                          }
                          if (value == 0.5) {
                            return Text(
                              'Med',
                              style: TextStyle(
                                fontSize: 12 * widget.scaleFactor,
                              ),
                            );
                          }
                          if (value == 0.25) {
                            return Text(
                              'Slow',
                              style: TextStyle(
                                fontSize: 12 * widget.scaleFactor,
                              ),
                            );
                          }
                          return Text(
                            'Off',
                            style: TextStyle(fontSize: 12 * widget.scaleFactor),
                          );
                        },
                        borderRadius: BorderRadius.circular(21),
                      )
                    : SegmentedButton<double>(
                        segments: [
                          ButtonSegment(
                            value: 1.0,
                            label: const Text('Fast'),
                            icon: Icon(
                              themeProvider.themeStyle == ThemeStyle.fruit
                                  ? LucideIcons.zap
                                  : Icons.speed,
                            ),
                          ),
                          const ButtonSegment(value: 0.5, label: Text('Med')),
                          const ButtonSegment(value: 0.25, label: Text('Slow')),
                          const ButtonSegment(value: 0.1, label: Text('Off')),
                        ],
                        selected: {settingsProvider.rgbAnimationSpeed},
                        onSelectionChanged: (Set<double> newSelection) {
                          AppHaptics.lightImpact(context.read<DeviceService>());
                          context.read<SettingsProvider>().setRgbAnimationSpeed(
                            newSelection.first,
                          );
                        },
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(21),
                            ),
                          ),
                          side: WidgetStateProperty.all(
                            const BorderSide(
                              color: Colors.transparent,
                              width: 0,
                            ),
                          ),
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.12);
                                }
                                return Colors.transparent;
                              }),
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return Theme.of(
                                    context,
                                  ).colorScheme.onSurface;
                                }
                                return Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7);
                              }),
                          textStyle:
                              WidgetStateProperty.resolveWith<TextStyle?>(
                                (states) => null,
                              ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontSelectionTile(
    BuildContext context,
    SettingsProvider settingsProvider,
  ) {
    return TvListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: const Icon(Icons.text_format_rounded),
      title: _buildTileTitle(context, 'App Font'),
      subtitle: _buildTileSubtitle(
        context,
        _getFontDisplayName(settingsProvider.appFont),
      ),
      onTap: () {
        AppHaptics.lightImpact(context.read<DeviceService>());
        FontSelectionDialog.show(context);
      },
    );
  }

  Widget _buildTileTitle(BuildContext context, String text) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontSize: 16 * widget.scaleFactor),
      ),
    );
  }

  Widget _buildTileSubtitle(BuildContext context, String text) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontSize: 12 * widget.scaleFactor),
      ),
    );
  }

  void _handleThemeModeChanged(BuildContext context, ThemeMode newMode) {
    AppHaptics.lightImpact(context.read<DeviceService>());
    context.read<ThemeProvider>().setThemeMode(newMode);

    final settingsProvider = context.read<SettingsProvider>();
    final isLightMode =
        newMode == ThemeMode.light ||
        (newMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.light);
    if (isLightMode && settingsProvider.useTrueBlack) {
      settingsProvider.toggleUseTrueBlack();
    }
  }

  void _handleThemeStyleChanged(BuildContext context, ThemeStyle style) {
    AppHaptics.lightImpact(context.read<DeviceService>());
    context.read<ThemeProvider>().setThemeStyle(style);

    final settingsProvider = context.read<SettingsProvider>();
    if (style == ThemeStyle.fruit) {
      settingsProvider.setUseNeumorphism(true);
      if (settingsProvider.useTrueBlack) {
        settingsProvider.toggleUseTrueBlack();
      }
      if (settingsProvider.useDynamicColor) {
        settingsProvider.toggleUseDynamicColor();
      }
      return;
    }

    settingsProvider.setUseNeumorphism(false);
    if (!settingsProvider.useTrueBlack) {
      settingsProvider.toggleUseTrueBlack();
    }
    if (!settingsProvider.useDynamicColor) {
      settingsProvider.toggleUseDynamicColor();
    }
    if (settingsProvider.isFirstRun && settingsProvider.appFont == 'default') {
      settingsProvider.setAppFont('rock_salt');
    }
  }
}
