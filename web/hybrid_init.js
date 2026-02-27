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
    const isIPadOS = !isMobiUA && navigator.maxTouchPoints > 4 && /Mac/i.test(ua);
    const hasTouch = navigator.maxTouchPoints > 1;
    const isNarrow = window.innerWidth < 1024;
    const isChromebook = /CrOS/i.test(ua);

    // Detection logic: Hybrid is now the default everywhere
    // Check for user override from SettingsProvider (persisted in localStorage)
    const storedMode = localStorage.getItem('flutter.audio_engine_mode');
    const override = storedMode ? storedMode.replace(/"/g, '') : null; // Remove JSON quotes if present

    let strategy = 'html5';
    let reason = "Defaulting to HTML5 engine for standard PWA background longevity.";

    if (override && override !== 'auto' && override !== 'standard') {
        strategy = override;
        reason = `User override: ${override}`;
    } else if (isChromebook) {
        reason = `Chromebook detected (CrOS) -> Defaulting to Hybrid. UA: ${ua.substring(0, 40)}...`;
    } else if (isMobiUA) {
        reason = `User-Agent match: ${ua.match(/Mobi|Android|iPhone|iPad/i)[0]} -> Defaulting to Hybrid`;
    } else if (isIPadOS) {
        reason = `iPadOS detected (maxTouchPoints: ${navigator.maxTouchPoints}, Mac UA) -> Defaulting to Hybrid`;
    } else if (hasTouch && isNarrow) {
        reason = `Touch device (${navigator.maxTouchPoints} pts) with narrow viewport (${window.innerWidth}px) -> Defaulting to Hybrid`;
    } else {
        reason = `Desktop environment (UA: ${ua.length > 50 ? ua.substring(0, 50) + '...' : ua}, Width: ${window.innerWidth}px, Touch: ${hasTouch}) -> Defaulting to Hybrid`;
    }

    if (override === 'standard') {
        console.log(`[Shakedown] Standard Engine selected by user. Custom JS engines will be dormant.`);
        window._shakedownAudioStrategy = 'standard';
        window._shakedownAudioReason = "User override: standard";
        return;
    }

    if (strategy === 'html5' && window._html5Audio) {
        window._gdarAudio = window._html5Audio;
        console.log(`[Shakedown] Override → HTML5 streaming engine. Reason: ${reason}`);
    } else if (strategy === 'passive' && window._passiveAudio) {
        window._gdarAudio = window._passiveAudio;
        console.log(`[Shakedown] Override → Passive audio engine. Reason: ${reason}`);
    } else if (strategy === 'hybrid' && window._hybridAudio) {
        window._gdarAudio = window._hybridAudio;
        console.log(`[Shakedown] ${override ? 'Override' : 'Auto'} → Hybrid Audio engine. Reason: ${reason}`);
    } else if (strategy === 'webaudio') {
        // window._gdarAudio is already set by gapless_audio_engine.js — no-op.
        console.log(`[Shakedown] Override → GDAR Web Audio API engine. Reason: ${reason}`);
    } else {
        console.log(`[Shakedown] Fallback processing: strategy ${strategy}. Reason: ${reason}`);
    }

    // Expose detection result and reason for diagnostic purposes.
    window._shakedownAudioStrategy = strategy;
    window._shakedownAudioReason = reason;
})();
