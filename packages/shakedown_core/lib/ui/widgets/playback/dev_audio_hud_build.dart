part of 'dev_audio_hud.dart';

extension _DevAudioHudBuild on _DevAudioHudState {
  Widget _buildHud(BuildContext context) {
    final audioProvider = widget.audioProvider;
    final labelsFontSize = widget.labelsFontSize;

    return StreamBuilder<HudSnapshot>(
      stream: audioProvider.hudSnapshotStream,
      initialData: audioProvider.currentHudSnapshot,
      builder: (context, snapshot) {
        final hud = snapshot.data;
        if (hud == null) return const SizedBox.shrink();

        _syncHeartbeatPulse(hud.isPlaying);
        _trackBgt(hud);
        _trackNet(hud);

        if (!widget.compact) {
          final summary = hud
              .toMap()
              .entries
              .map((e) => '${e.key}:${e.value}')
              .join(' • ');
          return Text(
            summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: labelsFontSize * 0.92,
              fontFamily: widget.fontFamily ?? 'RobotoMono',
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          );
        }

        final fields = {
          ...hud.toMap(),
          'SHD': _computeShield(hud),
          'GAP': _computeGap(hud),
          'BGT': _computeBgt(),
          'PM': widget.settingsProvider.performanceMode ? 'ON' : 'OFF',
          'NET': _computeNetDisplay(hud),
          'LG': _computeLastGap(hud),
        };
        final isFruitMode =
            context.read<ThemeProvider?>()?.themeStyle == ThemeStyle.fruit;
        final isFruitGlassOn =
            isFruitMode && widget.settingsProvider.fruitEnableLiquidGlass;

        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;
        final isTrueBlack =
            isDarkMode &&
            (context.read<SettingsProvider?>()?.useTrueBlack ?? false);

        final hudPadding = widget.compact
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 5)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 6);

        Widget hudContent = Container(
          key: const ValueKey('hud_always_expanded'),
          width: double.infinity,
          padding: hudPadding,
          decoration: BoxDecoration(
            color: isTrueBlack
                ? Colors.black
                : isFruitGlassOn
                ? Colors.transparent
                : Theme.of(context).colorScheme.surface.withValues(
                    alpha: isFruitMode ? 0.85 : 0.78,
                  ),
            borderRadius: BorderRadius.circular(isFruitMode ? 14 : 10),
            border: isTrueBlack
                ? Border.all(
                    color: widget.colorScheme.onSurface.withValues(alpha: 0.2),
                    width: 1.0,
                  )
                : (isFruitMode
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 0.5,
                        )
                      : null),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const keys = [
                'DFT',
                'HD',
                'BUF',
                'NX',
                'PF',
                'HF',
                'TX',
                'DET',
                'BG',
                'STB',
                'ENG',
                'AE',
                'V',
                'E',
                'ST',
                'PS',
                'SHD',
                'GAP',
                'BGT',
                'PM',
                'NET',
                'LG',
                'SIG',
                'MSG',
              ];

              return _buildHudFieldWrap(
                context: context,
                fields: fields,
                orderedKeys: keys,
                labelsFontSize: labelsFontSize,
                colorScheme: widget.colorScheme,
                fontFamily: widget.fontFamily,
                isFruit: isFruitMode,
                isTrueBlack: isTrueBlack,
                heartbeatActive: hud.hbActive,
                heartbeatNeeded: hud.hbNeeded,
                heartbeatEnabledBySettings: hud.heartbeatEnabledBySettings,
                isPlaying: hud.isPlaying,
                isHandoffCountdown: hud.isHandoffCountdown,
              );
            },
          ),
        );

        if (isFruitMode && !isTrueBlack) {
          hudContent = Padding(
            padding: EdgeInsets.symmetric(vertical: widget.compact ? 1.0 : 2.0),
            child: LiquidGlassWrapper(
              borderRadius: BorderRadius.circular(14),
              opacity: 0.85,
              child: hudContent,
            ),
          );
        }

        return hudContent;
      },
    );
  }

  Widget _buildHudFieldWrap({
    required BuildContext context,
    required Map<String, String> fields,
    required List<String> orderedKeys,
    required double labelsFontSize,
    required ColorScheme colorScheme,
    required String? fontFamily,
    required bool isFruit,
    required bool isTrueBlack,
    required bool heartbeatActive,
    required bool heartbeatNeeded,
    required bool heartbeatEnabledBySettings,
    required bool isPlaying,
    bool isHandoffCountdown = false,
  }) {
    const chipSpacing = 8.0;
    const sparklineChipWidth = 84.0;
    if (isPlaying) {
      _appendDriftSample(fields['DFT']);
      _appendHeadroomSample(fields['HD']);
    }
    final telemetryChips = <Widget>[];
    final sparklineValueChips = <Widget>[];
    final trendChips = <Widget>[];
    Widget? bgChip;
    Widget? detChip;
    Widget? errorChip;
    Widget? sigChip;
    Widget? msgChip;

    final baseTextColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.96);
    final keyTextColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    final chipBgColor = isTrueBlack
        ? Colors.black.withValues(alpha: 0.0)
        : colorScheme.onSurface.withValues(alpha: 0.06);

    final trendChipWidth = math.max(
      _heartbeatStackWidth(labelsFontSize),
      sparklineChipWidth,
    );
    final trendChipHeight = _heartbeatStackHeight(labelsFontSize);

    Widget buildTrendChip(
      List<double> history,
      String label,
      Color strokeColor, {
      double alpha = 0.92,
    }) {
      return Container(
        width: trendChipWidth,
        height: trendChipHeight,
        decoration: BoxDecoration(
          color: chipBgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: CustomPaint(
                size: Size(trendChipWidth, trendChipHeight),
                painter: _HudSparklinePainter(
                  values: history,
                  baseline: 0,
                  strokeColor: strokeColor.withValues(alpha: alpha),
                  guideColor: keyTextColor.withValues(alpha: 0.45),
                ),
              ),
            ),
            Positioned(
              bottom: 1,
              right: 2,
              child: Text(
                label,
                style: TextStyle(
                  color: keyTextColor.withValues(alpha: 0.6),
                  fontSize: labelsFontSize * 0.65,
                  fontWeight: FontWeight.w900,
                  fontFamily: fontFamily ?? 'RobotoMono',
                ),
              ),
            ),
          ],
        ),
      );
    }

    trendChips.add(
      buildTrendChip(_driftHistory, 'DFT', baseTextColor, alpha: 1.0),
    );
    trendChips.add(buildTrendChip(_headroomHistory, 'HD', baseTextColor));
    trendChips.add(
      buildTrendChip(_netHistory, 'NET', Colors.amberAccent, alpha: 0.9),
    );

    for (final key in orderedKeys) {
      final value = fields[key];
      if (value == null) continue;
      final bool isDynamic = key == 'MSG';

      double? chipWidth;
      if (!isDynamic) {
        chipWidth = 48;
        switch (key) {
          case 'DFT':
          case 'HD':
            chipWidth = 76;
            break;
          case 'NET':
            chipWidth = 68;
            break;
          case 'DET':
            chipWidth = 38;
            break;
          case 'ENG':
            chipWidth = 44;
            break;
          case 'SIG':
            chipWidth = 36;
            break;
          case 'BG':
            chipWidth = 68;
            break;
          case 'HF':
          case 'TX':
          case 'ST':
          case 'PF':
          case 'PS':
            chipWidth = 54;
            break;
          case 'V':
          case 'AE':
            chipWidth = 48;
            break;
          case 'SHD':
          case 'GAP':
            chipWidth = 52;
            break;
          case 'BGT':
            chipWidth = 62;
            break;
          case 'PM':
            chipWidth = 44;
            break;
          case 'E':
            chipWidth = 36;
            break;
          case 'LG':
            chipWidth = 58;
            break;
        }
      }

      Color finalChipBgColor = chipBgColor;
      Color finalBaseTextColor = baseTextColor;
      Color finalKeyTextColor = keyTextColor;
      bool hasClickableBorder = false;

      const interactiveKeys = ['ENG', 'HF', 'BG', 'STB', 'PF'];
      if (interactiveKeys.contains(key)) {
        hasClickableBorder = true;
      }

      if (key == 'E' && value != 'OK' && value != '--') {
        finalChipBgColor = Colors.redAccent.withValues(alpha: 0.9);
        finalBaseTextColor = Colors.white;
        finalKeyTextColor = Colors.white.withValues(alpha: 0.8);
      } else if (key == 'HD') {
        final driftValue = _parseDriftValue(value) ?? 0.0;
        if (driftValue < 0) {
          finalChipBgColor = Colors.redAccent.withValues(alpha: 0.8);
          finalBaseTextColor = Colors.white;
        } else if (driftValue < 5) {
          finalChipBgColor = Colors.orange.withValues(alpha: 0.8);
          finalBaseTextColor = Colors.black;
        } else if (driftValue > 20) {
          finalBaseTextColor = Colors.green;
        }
      } else if (key == 'PS') {
        if (value == 'BUF' || value == 'LD') {
          finalChipBgColor = Colors.orange.withValues(alpha: 0.7);
          finalBaseTextColor = Colors.black;
        } else if (value == 'RDY') {
          finalBaseTextColor = Colors.green;
        }
      } else if (key == 'AE') {
        final isSurvival = value.contains('+');
        if (value.startsWith('WA')) {
          finalBaseTextColor = Colors.cyan.shade700;
        } else if (value.startsWith('H5')) {
          finalBaseTextColor = Colors.lightBlueAccent;
        }
        if (isSurvival) {
          finalChipBgColor = Colors.indigoAccent.withValues(alpha: 0.85);
          finalBaseTextColor = Colors.white;
          finalKeyTextColor = Colors.white.withValues(alpha: 0.82);
        }
      } else if (key == 'SIG') {
        if (value == 'ISS') {
          finalChipBgColor = Colors.redAccent.withValues(alpha: 0.9);
          finalBaseTextColor = Colors.white;
        } else if (value == 'NTF') {
          finalChipBgColor = Colors.orange.withValues(alpha: 0.8);
          finalBaseTextColor = Colors.black;
        } else if (value == 'AGT') {
          finalBaseTextColor = Colors.lightBlueAccent;
        }
      } else if (key == 'ST') {
        if (isHandoffCountdown) {
          finalChipBgColor = Colors.orange.withValues(alpha: 0.9);
          finalBaseTextColor = Colors.black;
          finalKeyTextColor = Colors.black.withValues(alpha: 0.8);
        } else if (value == 'SUSP') {
          finalChipBgColor = Colors.redAccent.withValues(alpha: 0.8);
          finalBaseTextColor = Colors.white;
        }
      } else if (key == 'NX' && value != '00:00' && value != '--') {
        finalBaseTextColor = Colors.green;
      } else if (key == 'DFT') {
        final drift = _parseDriftValue(value) ?? 0.0;
        if (drift.abs() > 0.1) {
          finalBaseTextColor = Colors.redAccent;
        }
      } else if (key == 'V' && value.startsWith('HID')) {
        finalBaseTextColor = Colors.lightBlueAccent;
      } else if (key == 'STB') {
        if (value == 'STB') finalBaseTextColor = Colors.green;
        if (value == 'BAL') finalBaseTextColor = Colors.lightBlueAccent;
        if (value == 'MAX') finalBaseTextColor = Colors.orangeAccent;
      } else if (key == 'SHD') {
        switch (value) {
          case 'OK':
            finalChipBgColor = Colors.green.withValues(alpha: 0.7);
            finalBaseTextColor = Colors.white;
            finalKeyTextColor = Colors.white.withValues(alpha: 0.75);
            break;
          case 'SOFT':
            finalChipBgColor = Colors.amber.withValues(alpha: 0.75);
            finalBaseTextColor = Colors.black;
            finalKeyTextColor = Colors.black.withValues(alpha: 0.7);
            break;
          case 'RISK':
          case 'DEAD':
            finalChipBgColor = Colors.redAccent.withValues(alpha: 0.85);
            finalBaseTextColor = Colors.white;
            finalKeyTextColor = Colors.white.withValues(alpha: 0.8);
            break;
        }
      } else if (key == 'GAP') {
        switch (value) {
          case 'RDY':
            finalBaseTextColor = Colors.green;
            break;
          case 'LOW':
          case 'MISS':
            finalChipBgColor = Colors.redAccent.withValues(alpha: 0.9);
            finalBaseTextColor = Colors.white;
            finalKeyTextColor = Colors.white.withValues(alpha: 0.8);
            break;
        }
      } else if (key == 'BGT' && value != '--') {
        finalBaseTextColor = Colors.lightBlueAccent;
      } else if (key == 'PM') {
        if (value == 'ON') {
          finalChipBgColor = Colors.amber.withValues(alpha: 0.75);
          finalBaseTextColor = Colors.black;
          finalKeyTextColor = Colors.black.withValues(alpha: 0.7);
        }
      } else if (key == 'NET') {
        if (value.endsWith('...')) {
          finalBaseTextColor = Colors.amberAccent;
        } else if (value != '--') {
          double? netMs;
          if (value.endsWith('ms')) {
            netMs = double.tryParse(value.replaceAll('ms', ''));
          } else if (value.endsWith('s')) {
            final sec = double.tryParse(value.replaceAll('s', ''));
            if (sec != null) netMs = sec * 1000;
          }
          if (netMs != null) {
            if (netMs < 800) {
              finalBaseTextColor = Colors.green;
            } else if (netMs < 2000) {
              finalChipBgColor = Colors.orange.withValues(alpha: 0.8);
              finalBaseTextColor = Colors.black;
              finalKeyTextColor = Colors.black.withValues(alpha: 0.7);
            } else {
              finalChipBgColor = Colors.redAccent.withValues(alpha: 0.85);
              finalBaseTextColor = Colors.white;
              finalKeyTextColor = Colors.white.withValues(alpha: 0.8);
            }
          }
        }
      } else if (key == 'LG' && value != '--') {
        final gapMs = _parseGapMs(value);
        if (gapMs < 5) {
          finalBaseTextColor = Colors.green;
        } else if (gapMs < 50) {
          finalChipBgColor = Colors.amber.withValues(alpha: 0.75);
          finalBaseTextColor = Colors.black;
          finalKeyTextColor = Colors.black.withValues(alpha: 0.7);
        } else {
          finalChipBgColor = Colors.redAccent.withValues(alpha: 0.85);
          finalBaseTextColor = Colors.white;
          finalKeyTextColor = Colors.white.withValues(alpha: 0.8);
        }
      }

      Widget chip = Container(
        constraints: chipWidth != null
            ? BoxConstraints(minWidth: chipWidth)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 2.3, vertical: 2),
        decoration: BoxDecoration(
          color: finalChipBgColor,
          borderRadius: BorderRadius.circular(6),
          border: hasClickableBorder
              ? Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  width: 1.0,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${key == 'DET' ? 'D' : key}:',
              style: TextStyle(
                color: finalKeyTextColor,
                fontWeight: FontWeight.w700,
                fontSize: labelsFontSize * 0.84,
                fontFamily: fontFamily ?? 'RobotoMono',
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (key == 'MSG' && value.length > 30)
              Flexible(
                child: SizedBox(
                  height: labelsFontSize * 1.2,
                  child: Marquee(
                    text: value,
                    style: TextStyle(
                      color: finalBaseTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: labelsFontSize * 0.84,
                      fontFamily: fontFamily ?? 'RobotoMono',
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    scrollAxis: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    blankSpace: 20.0,
                    velocity: 30.0,
                    pauseAfterRound: const Duration(seconds: 1),
                    accelerationDuration: const Duration(seconds: 1),
                    accelerationCurve: Curves.linear,
                    decelerationDuration: const Duration(milliseconds: 500),
                    decelerationCurve: Curves.easeOut,
                  ),
                ),
              )
            else if (key == 'MSG')
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: finalBaseTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: labelsFontSize * 0.84,
                    fontFamily: fontFamily ?? 'RobotoMono',
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              )
            else if (key == 'AE' && value.contains('+'))
              Flexible(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      color: finalBaseTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: labelsFontSize * 0.84,
                      fontFamily: fontFamily ?? 'RobotoMono',
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    children: [
                      TextSpan(text: value.replaceAll('+', '')),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: _heartbeatPulseOn ? 1.0 : 0.4,
                          child: Text(
                            '+',
                            style: TextStyle(
                              color: finalBaseTextColor,
                              fontWeight: FontWeight.w700,
                              fontSize: labelsFontSize * 0.84,
                              fontFamily: fontFamily ?? 'RobotoMono',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: finalBaseTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: labelsFontSize * 0.84,
                    fontFamily: fontFamily ?? 'RobotoMono',
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (key == 'BG' && heartbeatEnabledBySettings) ...[
              const SizedBox(width: 4),
              RepaintBoundary(
                child: _buildTrafficLightHeartbeat(
                  labelsFontSize,
                  colorScheme,
                  active: heartbeatActive,
                  needed: heartbeatNeeded,
                  enabledBySettings: true,
                  isPlaying: isPlaying,
                  horizontal: true,
                ),
              ),
            ],
            if (hasClickableBorder)
              Padding(
                padding: const EdgeInsets.only(left: 1),
                child: Icon(
                  Icons.arrow_drop_down,
                  size: labelsFontSize * 0.9,
                  color: finalKeyTextColor,
                ),
              ),
          ],
        ),
      );

      if (key == 'MSG') {
        chip = GestureDetector(
          onTap: () => widget.audioProvider.clearLastIssue(),
          child: chip,
        );
      }

      if (interactiveKeys.contains(key)) {
        chip = GestureDetector(
          onTapDown: (details) => _showHudMenu(
            context: context,
            globalPosition: details.globalPosition,
            key: key,
            sp: widget.settingsProvider,
          ),
          child: MouseRegion(cursor: SystemMouseCursors.click, child: chip),
        );
      }

      final tooltip = _hudFieldTooltip(key, value);
      if (tooltip.isNotEmpty) {
        if (isFruit) {
          chip = FruitTooltip(message: tooltip, child: chip);
        } else {
          chip = Tooltip(
            message: tooltip,
            preferBelow: false,
            verticalOffset: 20,
            child: chip,
          );
        }
      }

      if (key == 'V') {
        chip = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: chip,
        );
      }

      if (key == 'DET') {
        detChip = chip;
      } else if (key == 'E') {
        errorChip = chip;
      } else if (key == 'DFT' || key == 'HD') {
        sparklineValueChips.add(chip);
      } else if (key == 'BG') {
        bgChip = chip;
      } else if (key == 'SIG') {
        sigChip = chip;
      } else if (key == 'MSG') {
        msgChip = chip;
      } else {
        telemetryChips.add(chip);
      }
    }

    final middleRowChips = <Widget>[];
    middleRowChips.addAll(sparklineValueChips);
    if (bgChip != null) {
      middleRowChips.add(bgChip);
    }
    middleRowChips.addAll(telemetryChips);

    final sigAndMsgChildren = <Widget>[];
    if (detChip != null) sigAndMsgChildren.add(detChip);
    if (errorChip != null) sigAndMsgChildren.add(errorChip);
    if (sigChip != null) sigAndMsgChildren.add(sigChip);
    if (msgChip != null) sigAndMsgChildren.add(msgChip);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: chipSpacing,
          runSpacing: chipSpacing,
          children: trendChips,
        ),
        if (middleRowChips.isNotEmpty) const SizedBox(height: chipSpacing),
        if (middleRowChips.isNotEmpty)
          Wrap(
            spacing: chipSpacing,
            runSpacing: chipSpacing,
            children: middleRowChips,
          ),
        if (sigAndMsgChildren.isNotEmpty) ...[
          const SizedBox(height: chipSpacing),
          Wrap(
            spacing: chipSpacing,
            runSpacing: chipSpacing,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: sigAndMsgChildren,
          ),
        ],
      ],
    );
  }
}
