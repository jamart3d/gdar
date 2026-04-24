/**
 * Hybrid Audio Engine Dispatcher
 *
 * Runs after both html5_audio_engine.js and gapless_audio_engine.js are loaded.
 * Detects mobile vs desktop and assigns window._gdarAudio to the appropriate
 * engine — transparent to the Dart interop layer in gapless_player_web.dart.
 *
 * Detection logic:
 *   1. /Mobi|Android|iPhone|iPad/ in userAgent (all major mobile browsers)
 *   2. maxTouchPoints > 1 AND viewport width < 1024 (tablet guard)
 *   Touch-screen laptops running full Chrome will not be mistakenly flagged
 *   because their viewport width is typically ≥ 1024.
 *
 * The chosen strategy can be confirmed at runtime:
 *   window._gdarAudio.getState().contextState
 *   → 'html5'       : HTML5 streaming engine (mobile)
 *   → 'running'|... : GDAR Web Audio API engine (desktop)
 *
 * Requires audio_utils.js to be loaded before this script.
 * audio_utils.js defines window._gdarIsHeartbeatNeeded(), which is called
 * by all engines at state-emission time. If audio_utils.js is absent or
 * loaded after the engines, heartbeat detection will throw silently.
 */
(function () {
    'use strict';

    // Safe Logger Utility
    const _log = (window._gdarLogger || console);

    // FLUSH Logic: If ?flush=true is in URL, clear GDAR keys for a fresh start.
    // Targets only flutter.* (SharedPreferences) and known raw GDAR keys — does NOT
    // wipe unrelated keys that other scripts on the same origin may have written.
    // Use sessionStorage to ensure it only happens ONCE per session (allowing reload to persist).
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('flush') === 'true' && !sessionStorage.getItem('shakedown_flushed')) {
        const keysToRemove = Object.keys(localStorage).filter(k =>
            k.startsWith('flutter.') ||
            k === 'audio_engine_mode' ||
            k === 'allow_hidden_web_audio' ||
            k === 'gdar_web_error_log_v1' ||
            k === 'gdar_pwa_visited'
        );
        keysToRemove.forEach(k => localStorage.removeItem(k));
        sessionStorage.setItem('shakedown_flushed', 'true');
        console.warn('%c[Shakedown] localStorage FLUSHED via URL parameter (' + keysToRemove.length + ' keys removed).', 'color: #ff0000; font-weight: bold;');
    }

    const ua = navigator.userAgent;
    const isMobiUA = /Mobi|Android|iPhone|iPad/i.test(ua);
    const isIPadOS = !isMobiUA && navigator.maxTouchPoints > 4 && /Mac/i.test(ua);
    const hasTouch = navigator.maxTouchPoints > 1;
    const isNarrow = window.innerWidth < 1024;
    const isChromebook = /CrOS/i.test(ua);
    let isStandalonePwa = false;
    try {
        isStandalonePwa =
            typeof window.matchMedia === 'function' &&
            window.matchMedia('(display-mode: standalone)').matches;
    } catch (_) { }
    try {
        isStandalonePwa = isStandalonePwa || navigator.standalone === true;
    } catch (_) { }

    // Check for user override from SettingsProvider (persisted in localStorage)
    const PREF_KEY = 'flutter.audio_engine_mode';
    const RAW_KEY = 'audio_engine_mode';
    const storedMode = localStorage.getItem(PREF_KEY) || localStorage.getItem(RAW_KEY);

    // Remove JSON quotes if present (standard SharedPreferences behavior)
    let override = storedMode ? storedMode.replace(/^"|"$/g, '').trim() : null;

    if (override) {
        override = override.toLowerCase().trim();
        if (override === 'webaudio') override = 'webAudio';
    }

    let strategy = 'hybrid'; // Desktop Default
    let reason = 'Defaulting to Hybrid mode (HTML5 start + Web Audio handoff).';
    const lpDpr = window.devicePixelRatio || 1;
    const lpCores = navigator.hardwareConcurrency || 0;
    const isMobileLike = isMobiUA || isIPadOS || (hasTouch && isNarrow);
    const isLowCoreCount =
        lpCores > 0 && (lpCores <= 2 || (lpCores <= 4 && lpDpr < 2.0));
    const isLowPowerMobile = isMobileLike && isLowCoreCount;

    if (override && override !== 'auto' && override !== 'standard') {
        strategy = override;
        reason = `User override detected: ${override}`;
    } else if (override === 'standard') {
        strategy = 'standard';
        reason = "User override: standard engine (Native just_audio)";
    } else if (isChromebook) {
        strategy = 'webAudio';
        reason = `Chromebook detected (CrOS) -> Web Audio API enabled.`;
    } else if (isStandalonePwa) {
        if (isLowPowerMobile) {
            strategy = 'html5';
            reason = 'Installed low-power PWA detected -> HTML5 streaming engine.';
        } else {
            strategy = 'hybrid';
            reason = 'Installed PWA detected -> Hybrid orchestrator.';
        }
    } else if (isMobileLike) {
        strategy = 'html5';
        reason = `Mobile/Tablet browser tab detected -> HTML5 streaming engine.`;
    }
    console.log(`[Shakedown] Strategy decision BEFORE fallback: ${strategy}. Reason: ${reason}`);

    if (override === 'standard') {
        _log.log(`[Shakedown] Standard Engine selected by user. Custom JS engines will be dormant.`);
        window._shakedownAudioStrategy = 'standard';
        window._shakedownAudioReason = "User override: standard";
        return;
    }

    // Engine Assignment Logic
    // We try the detected strategy first, but fall back to whatever is available
    // to avoid the fatal "null: type 'Null' is not a subtype of type 'JSObject'" crash in Dart.
    let selectedEngine = null;

    if (strategy === 'hybrid' && window._hybridAudio) {
        selectedEngine = window._hybridAudio;
    } else if (strategy === 'passive' && window._passiveAudio) {
        selectedEngine = window._passiveAudio;
    } else if (strategy === 'html5' && window._html5Audio) {
        selectedEngine = window._html5Audio;
    } else if (strategy === 'webAudio' && window._gdarAudio) {
        selectedEngine = window._gdarAudio;
    }

    // Final Fallback: If the preferred strategy is missing, grab ANYTHING that exists.
    if (!selectedEngine) {
        console.warn(`[Shakedown] Preferred engine ${strategy} NOT FOUND. Checking availability: hybrid=${!!window._hybridAudio}, webAudio=${!!window._gdarAudio}, html5=${!!window._html5Audio}, passive=${!!window._passiveAudio}`);

        // If the user explicitly requested Web Audio, DO NOT allow a silent fallback to Hybrid/HTML5
        // which would introduce gaps.
        if (override === 'webAudio') {
            _log.error(`[Shakedown] STRICT SELECTION FAILURE: User requested 'webAudio' but window._gdarAudio is missing. Blocking fallback to avoid gaps.`);
        } else {
            selectedEngine = window._hybridAudio || window._gdarAudio || window._html5Audio || window._passiveAudio;
            if (selectedEngine) {
                const fallbackType = (selectedEngine === window._hybridAudio) ? 'hybrid' :
                    (selectedEngine === window._gdarAudio) ? 'webAudio' :
                        (selectedEngine === window._html5Audio) ? 'html5' : 'passive';
                _log.warn(`[Shakedown] Strategy ${strategy} unavailable. Falling back to ${fallbackType}.`);
                strategy = fallbackType;
            }
        }
    }

    if (selectedEngine) {
        window._gdarAudio = selectedEngine;
        if (strategy === 'hybrid' && selectedEngine === window._hybridAudio) {
            selectedEngine.engineType = 'hybrid';
        }
        _log.log(`[Shakedown] FINAL STRATEGY: ${strategy}. (Selected: ${selectedEngine.engineType || 'Unknown'}). Override: ${override}`);

        // Advanced Hybrid Settings Sync - Universal across all JS engines
        try {
            const bgMode = localStorage.getItem('flutter.hybrid_background_mode') || '"heartbeat"';
            const handoffMode = localStorage.getItem('flutter.hybrid_handoff_mode') || '"buffered"';
            const cleanBgMode = bgMode.replace(/"/g, '').toLowerCase();
            const cleanHandoffMode = handoffMode.replace(/"/g, '').toLowerCase();

            // Sync to the primary selected engine
            if (selectedEngine.setHybridBackgroundMode) {
                selectedEngine.setHybridBackgroundMode(cleanBgMode);
            }
            if (selectedEngine.setHybridHandoffMode) {
                selectedEngine.setHybridHandoffMode(cleanHandoffMode);
            }

            // Sync to underlying engines if they are globally available but not selected
            // (e.g. gapless engine needs to know it's in survival mode even if orchestrator is driving it)
            if (window._hybridAudio && window._hybridAudio !== selectedEngine) {
                window._hybridAudio.setHybridBackgroundMode(cleanBgMode);
            }
            if (window._gdarAudio && window._gdarAudio !== selectedEngine) {
                if (window._gdarAudio.setHybridBackgroundMode) window._gdarAudio.setHybridBackgroundMode(cleanBgMode);
            }
            if (window._html5Audio && window._html5Audio !== selectedEngine) {
                if (window._html5Audio.setHybridBackgroundMode) window._html5Audio.setHybridBackgroundMode(cleanBgMode);
            }
        } catch (e) {
            _log.error('[Shakedown] Failed to sync advanced hybrid settings:', e.message);
        }

        console.log('[Shakedown] window._gdarAudio is now configured:', window._gdarAudio.engineType);

        // Start the background tick scheduler for engines that need it.
        // Passive and standard engines use their own timing — no worker needed.
        if (strategy !== 'passive' && strategy !== 'standard') {
            if (window._gdarScheduler) window._gdarScheduler.start();
        }

        // MediaSession action handlers — install once for non-hybrid strategies.
        // The hybrid orchestrator installs its own handlers inside _setupMediaSession();
        // all other engines expose play/pause/seek/seekToIndex but not next()/previous(),
        // so we derive navigation from getState().index + seekToIndex().
        if (strategy !== 'hybrid' && window._gdarMediaSession && selectedEngine) {
            window._gdarMediaSession.setActionHandlers({
                onPlay: () => {
                    selectedEngine.play && selectedEngine.play();
                },
                onPause: () => {
                    selectedEngine.pause && selectedEngine.pause();
                },
                onNext: () => {
                    const s = selectedEngine.getState?.() || {};
                    const nextIdx = (typeof s.index === 'number' ? s.index : -1) + 1;
                    if (nextIdx >= 0 && nextIdx < (s.playlistLength || 0)) {
                        selectedEngine.seekToIndex && selectedEngine.seekToIndex(nextIdx);
                    }
                },
                onPrevious: () => {
                    const s = selectedEngine.getState?.() || {};
                    const curIdx = typeof s.index === 'number' ? s.index : 0;
                    selectedEngine.seekToIndex && selectedEngine.seekToIndex(Math.max(0, curIdx - 1));
                },
                onSeekTo: (e) => {
                    const t = Number(e && e.seekTime);
                    if (!Number.isFinite(t) || t < 0) return;
                    selectedEngine.seek && selectedEngine.seek(t);
                },
                onSeekBackward: (e) => {
                    const s = selectedEngine.getState?.() || {};
                    const pos = Number(s.position) || 0;
                    const offset = Number(e && e.seekOffset) || 10;
                    selectedEngine.seek && selectedEngine.seek(Math.max(0, pos - offset));
                },
                onSeekForward: (e) => {
                    const s = selectedEngine.getState?.() || {};
                    const pos = Number(s.position) || 0;
                    const dur = Number(s.duration);
                    const offset = Number(e && e.seekOffset) || 10;
                    const target = pos + offset;
                    selectedEngine.seek && selectedEngine.seek(
                        Number.isFinite(dur) && dur > 0 ? Math.min(target, dur) : target
                    );
                },
            });
            _log.log(`[Shakedown] MediaSession action handlers installed for strategy: ${strategy}`);
        }
    } else {
        _log.error(`[Shakedown] FATAL: No audio engine scripts loaded successfully or strict selection failed. Strategy: ${strategy}, Override: ${override}`);
    }

    // Expose detection results for diagnostics and Dart-side alignment.
    window._gdarIsMobile = (isMobiUA || isIPadOS || (hasTouch && isNarrow));
    window._gdarDetectedAsLowPower = isLowPowerMobile;

    // Diagnostic: Log all localStorage keys related to audio for debugging
    try {
        const audioKeys = Object.keys(localStorage).filter(k => k.toLowerCase().includes('audio'));
        if (audioKeys.length > 0) {
            console.log('[Shakedown] Diagnostic - Audio Keys in LocalStorage:', audioKeys.map(k => `${k}=${localStorage.getItem(k)}`).join(', '));
        }
    } catch (_) { }

    // Expose detection result and reason for diagnostic purposes.
    window._shakedownAudioStrategy = strategy;
    window._shakedownAudioReason = reason;

})();
