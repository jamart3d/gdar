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

        final scheduleLeadSeconds = _computeScheduleLeadSeconds(hud);
        final hudMap = hud.toMap();

        if (hud.isPlaying) {
          _appendDriftSample(hudMap['DFT']);
          _appendHeadroomSample(hudMap['HD']);
          _appendSchSample(scheduleLeadSeconds);
          _appendDecSample(hud.lastDecodeMs);
          _appendBctSample(hud.lastConcatMs);
        }

        // Derive engine booleans for gated visibility
        final isWA = hud.engine == 'WBA';
        final isHybrid = hud.engine == 'HYB' || hud.engine == 'AUT';
        final waSubEngineActive = hud.activeEngine.startsWith('WA');

        if (!widget.compact) {
          final summary = hudMap.entries
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
          ...hudMap,
          'SHD': _computeShield(hud),
          'GAP': _computeGap(hud),
          'BGT': _computeBgt(),
          'PM': widget.settingsProvider.performanceMode ? 'ON' : 'OFF',
          'NET': _computeNetDisplay(hud),
          'LG': _computeLastGap(hud),
          // Advanced telemetry chips
          'SCH': scheduleLeadSeconds?.toStringAsFixed(3) ?? '--',
          'LAT': hud.outputLatencyMs?.toStringAsFixed(1) ?? '--',
          'DEC': hud.lastDecodeMs?.toStringAsFixed(1) ?? '--',
          'BCT': hud.lastConcatMs?.toStringAsFixed(1) ?? '--',
          'ERR': hud.failedTrackCount?.toString() ?? '0',
          'WTC': hud.workerTickCount?.toString() ?? '--',
          'SR': hud.sampleRate != null
              ? '${(hud.sampleRate! / 1000).toStringAsFixed(1)}k'
              : '--',
          'CAC': hud.decodedCacheSize?.toString() ?? '--',
          'HS': hud.handoffState ?? '--',
          'HAT': hud.handoffAttemptCount?.toString() ?? '--',
          'HPD': hud.lastHandoffPollCount?.toString() ?? '--',
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
            builder: (context, _) {
              final showHybridControls = isHybrid;
              final showNetControls = isWA || isHybrid;
              final showWaTelemetry = isWA || (isHybrid && waSubEngineActive);
              final orderedKeys = [
                'ENG',
                if (showHybridControls) 'HF',
                if (showNetControls) 'BG',
                if (showHybridControls) 'STB',
                if (showNetControls) 'PF',
                'AE',
                'ST',
                'PS',
                'SHD',
                'GAP',
                'PM',
                if (showWaTelemetry) ...[
                  'LAT',
                  'ERR',
                  'WTC',
                  'SR',
                  'CAC',
                  'SCH',
                  'DEC',
                  'BCT',
                ],
                if (showHybridControls) ...[
                  'HS',
                  if (!waSubEngineActive) 'HAT',
                ],
                'BUF',
                'NX',
                'LG',
                'BGT',
                'DET',
                'E',
                'SIG',
                'MSG',
              ];

              return _buildHudFieldWrap(
                context: context,
                fields: fields,
                orderedKeys: orderedKeys,
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
                isWA: isWA,
                isHybrid: isHybrid,
                waSubEngineActive: waSubEngineActive,
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
    required bool isWA,
    required bool isHybrid,
    required bool waSubEngineActive,
  }) {
    const chipSpacing = 8.0;
    const sparklineChipWidth = 84.0;
    final showNetTelemetry = isWA || isHybrid;
    final trendChips = <Widget>[];
    final controlChips = <Widget>[];
    final stateChips = <Widget>[];
    final metricChips = <Widget>[];
    final sigAndMsgChildren = <Widget>[];

    const controlKeys = {'ENG', 'HF', 'BG', 'STB', 'PF'};
    const metricKeys = {'BUF', 'NX', 'LG', 'BGT', 'DET'};
    const messagingKeys = {'SIG', 'MSG', 'E'};
    const interactiveKeys = {'ENG', 'HF', 'BG', 'STB', 'PF'};

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
      String? currentValue,
      bool dimmed = false,
    }) {
      final labelBadgeColor = colorScheme.surface.withValues(
        alpha: isTrueBlack ? 0.42 : 0.78,
      );
      final valueBadgeColor = colorScheme.surface.withValues(
        alpha: isTrueBlack ? 0.56 : 0.9,
      );
      final labelColor = strokeColor.withValues(alpha: dimmed ? 0.72 : 0.96);
      final valueColor = colorScheme.onSurface.withValues(
        alpha: dimmed ? 0.88 : 0.98,
      );
      final chip = Container(
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
                  strokeColor: strokeColor.withValues(
                    alpha: dimmed ? 0.35 : alpha,
                  ),
                  guideColor: keyTextColor.withValues(alpha: 0.45),
                ),
              ),
            ),
            Positioned(
              top: 1,
              left: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: labelBadgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: labelsFontSize * 0.68,
                      fontWeight: FontWeight.w900,
                      fontFamily: fontFamily ?? 'RobotoMono',
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
            if (currentValue != null)
              Positioned(
                bottom: 1,
                right: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: valueBadgeColor,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: strokeColor.withValues(alpha: 0.24),
                      width: 0.6,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    child: Text(
                      currentValue,
                      style: TextStyle(
                        color: valueColor,
                        fontSize: labelsFontSize * 0.82,
                        fontWeight: FontWeight.w800,
                        fontFamily: fontFamily ?? 'RobotoMono',
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
      return _wrapHudTooltip(
        child: chip,
        key: label,
        value: currentValue ?? '--',
        isFruit: isFruit,
      );
    }

    trendChips.add(
      buildTrendChip(
        _driftHistory,
        'DFT',
        baseTextColor,
        alpha: 1.0,
        currentValue: isPlaying ? fields['DFT'] : '--',
      ),
    );
    trendChips.add(
      buildTrendChip(
        _headroomHistory,
        'HD',
        baseTextColor,
        dimmed: isWA,
        currentValue: fields['HD'],
      ),
    );
    if (showNetTelemetry) {
      trendChips.add(
        buildTrendChip(
          _netHistory,
          'NET',
          Colors.amberAccent.withValues(alpha: 0.9),
          alpha: 0.9,
          currentValue: fields['NET'],
        ),
      );
    }

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
            chipWidth = 32;
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
            chipWidth = 72;
            break;
          case 'SCH':
            chipWidth = 66;
            break;
          case 'LAT':
          case 'DEC':
          case 'BCT':
          case 'SR':
          case 'HPD':
            chipWidth = 54;
            break;
          case 'ERR':
          case 'CAC':
          case 'HAT':
            chipWidth = 40;
            break;
          case 'WTC':
            chipWidth = 62;
            break;
          case 'HS':
            chipWidth = 46;
            break;
        }
      }

      Color finalChipBgColor = chipBgColor;
      Color finalBaseTextColor = baseTextColor;
      Color finalKeyTextColor = keyTextColor;
      bool hasClickableBorder = false;

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
      } else if (key == 'SCH') {
        final drift = double.tryParse(value) ?? 0.0;
        if (drift.abs() > 0.1) {
          finalBaseTextColor = Colors.redAccent;
        } else if (drift.abs() > 0.01) {
          finalBaseTextColor = Colors.orangeAccent;
        }
      } else if (key == 'DEC') {
        final decMs = double.tryParse(value) ?? 0.0;
        if (decMs > 300) finalBaseTextColor = Colors.orangeAccent;
        if (decMs > 800) finalBaseTextColor = Colors.redAccent;
      } else if (key == 'BCT') {
        final bctMs = double.tryParse(value) ?? 0.0;
        if (bctMs > 50) finalBaseTextColor = Colors.orangeAccent;
        if (bctMs > 150) finalBaseTextColor = Colors.redAccent;
      } else if (key == 'ERR' && value != '0') {
        finalChipBgColor = Colors.redAccent.withValues(alpha: 0.9);
        finalBaseTextColor = Colors.white;
        finalKeyTextColor = Colors.white.withValues(alpha: 0.8);
      } else if (key == 'HS' && value != 'IDLE') {
        finalBaseTextColor = Colors.orangeAccent;
      } else if (key == 'HAT' && (int.tryParse(value) ?? 0) > 1) {
        finalBaseTextColor = Colors.orangeAccent;
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

      chip = _wrapHudTooltip(
        child: chip,
        key: key,
        value: value,
        isFruit: isFruit,
      );

      if (messagingKeys.contains(key)) {
        sigAndMsgChildren.add(chip);
      } else if (controlKeys.contains(key)) {
        controlChips.add(chip);
      } else if (metricKeys.contains(key)) {
        metricChips.add(chip);
      } else {
        stateChips.add(chip);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: chipSpacing,
          runSpacing: chipSpacing,
          children: trendChips,
        ),
        if (controlChips.isNotEmpty) ...[
          const SizedBox(height: chipSpacing),
          Wrap(
            spacing: chipSpacing,
            runSpacing: chipSpacing,
            children: controlChips,
          ),
        ],
        if (stateChips.isNotEmpty) ...[
          const SizedBox(height: chipSpacing),
          Wrap(
            spacing: chipSpacing,
            runSpacing: chipSpacing,
            children: stateChips,
          ),
        ],
        if (metricChips.isNotEmpty) ...[
          const SizedBox(height: chipSpacing),
          Wrap(
            spacing: chipSpacing,
            runSpacing: chipSpacing,
            children: metricChips,
          ),
        ],
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
