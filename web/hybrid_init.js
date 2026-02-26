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

    const ua = navigator.userAgent;
    const isMobiUA = /Mobi|Android|iPhone|iPad/i.test(ua);
    const hasTouch = navigator.maxTouchPoints > 1;
    const isNarrow = window.innerWidth < 1024;
    const isChromebook = /CrOS/i.test(ua);

    // Detection logic: mobile UA OR (touch + narrow viewport)
    // EXCLUSION: Chromebooks (CrOS) often have touch + narrow viewports but are desktop-class.
    // Check for user override from SettingsProvider (persisted in localStorage)
    const storedMode = localStorage.getItem('flutter.audio_engine_mode');
    const override = storedMode ? storedMode.replace(/"/g, '') : null; // Remove JSON quotes if present

    let isMobile = (isMobiUA || (hasTouch && isNarrow)) && !isChromebook;
    let strategy = isMobile ? 'html5' : 'webaudio';
    let reason = "";

    if (override && override !== 'auto' && override !== 'standard') {
        strategy = override;
        reason = `User override: ${override}`;
        isMobile = (strategy === 'html5');
    } else if (isChromebook) {
        reason = `Chromebook detected (CrOS) -> Desktop Engine forced. UA: ${ua.substring(0, 40)}...`;
    } else if (isMobiUA) {
        reason = `User-Agent match: ${ua.match(/Mobi|Android|iPhone|iPad/i)[0]}`;
    } else if (hasTouch && isNarrow) {
        reason = `Touch device (${navigator.maxTouchPoints} pts) with narrow viewport (${window.innerWidth}px)`;
    } else {
        reason = `Desktop environment (UA: ${ua.length > 50 ? ua.substring(0, 50) + '...' : ua}, Width: ${window.innerWidth}px, Touch: ${hasTouch})`;
    }

    if (override === 'standard') {
        console.log(`[Shakedown] Standard Engine selected by user. Custom JS engines will be dormant.`);
        window._shakedownAudioStrategy = 'standard';
        window._shakedownAudioReason = "User override: standard";
        return;
    }

    if (isMobile && window._html5Audio) {
        window._gdarAudio = window._html5Audio;
        console.log(`[Shakedown] ${override ? 'Override' : 'Mobile detected'} → HTML5 streaming engine. Reason: ${reason}`);
    } else {
        console.log(`[Shakedown] ${override ? 'Override' : 'Desktop detected'} → GDAR Web Audio API engine. Reason: ${reason}`);
        // window._gdarAudio is already set by gapless_audio_engine.js — no-op.
    }

    // Expose detection result and reason for diagnostic purposes.
    window._shakedownAudioStrategy = strategy;
    window._shakedownAudioReason = reason;
})();
