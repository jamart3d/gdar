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
              final showHybridHandoffTelemetry =
                  showHybridControls && fields['HF'] != 'OFF';
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
                if (showHybridHandoffTelemetry) ...[
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
}
