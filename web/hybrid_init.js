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
 */
(function () {
    'use strict';

    // Safe Logger Utility
    const _log = (window._gdarLogger || console);

    // FLUSH Logic: If ?flush=true is in URL, clear localStorage for a fresh start.
    // Use sessionStorage to ensure it only happens ONCE per session (allowing reload to persist).
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.get('flush') === 'true' && !sessionStorage.getItem('shakedown_flushed')) {
        localStorage.clear();
        sessionStorage.setItem('shakedown_flushed', 'true');
        console.warn('%c[Shakedown] localStorage FLUSHED via URL parameter.', 'color: #ff0000; font-weight: bold;');
    }

    const ua = navigator.userAgent;
    const isMobiUA = /Mobi|Android|iPhone|iPad/i.test(ua);
    const isIPadOS = !isMobiUA && navigator.maxTouchPoints > 4 && /Mac/i.test(ua);
    const hasTouch = navigator.maxTouchPoints > 1;
    const isNarrow = window.innerWidth < 1024;
    const isChromebook = /CrOS/i.test(ua);

    // Detection logic: PWA/Mobile = HTML5, Desktop = Web Audio
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

    let strategy = 'webAudio'; // Desktop Default
    let reason = 'Defaulting to Web Audio mode (Desktop).';

    if (override && override !== 'auto' && override !== 'standard') {
        strategy = override;
        reason = `User override detected: ${override}`;
    } else if (override === 'standard') {
        strategy = 'standard';
        reason = "User override: standard engine (Native just_audio)";
    } else if (isChromebook) {
        strategy = 'webAudio';
        reason = `Chromebook detected (CrOS) -> Web Audio API enabled.`;
    } else if (isMobiUA || isIPadOS || (hasTouch && isNarrow)) {
        // Mobile/PWA "Fresh Start" should always be HTML5
        strategy = 'html5';
        reason = `Mobile/Tablet/PWA environment detected -> HTML5 streaming engine (Fresh Start).`;
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
        _log.log(`[Shakedown] FINAL STRATEGY: ${strategy}. (Selected: ${selectedEngine.engineType || 'Unknown'}). Override: ${override}`);

        // Advanced Hybrid Settings Sync
        if (selectedEngine === window._hybridAudio) {
            try {
                const bgMode = localStorage.getItem('flutter.hybrid_background_mode') || '"html5"';
                const handoffMode = localStorage.getItem('flutter.hybrid_handoff_mode') || '"buffered"';

                selectedEngine.setHybridBackgroundMode(bgMode.replace(/"/g, '').toLowerCase());
                selectedEngine.setHybridHandoffMode(handoffMode.replace(/"/g, '').toLowerCase());
            } catch (e) {
                _log.error('[Shakedown] Failed to sync advanced hybrid settings:', e.message);
            }
        }

        console.log('[Shakedown] window._gdarAudio is now configured:', window._gdarAudio.engineType);
    } else {
        _log.error(`[Shakedown] FATAL: No audio engine scripts loaded successfully or strict selection failed. Strategy: ${strategy}, Override: ${override}`);
    }

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
