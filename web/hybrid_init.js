/**
 * Hybrid Audio Engine Dispatcher
 *
 * Runs after both relisten_audio_engine.js and gapless_audio_engine.js are loaded.
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
 *   → 'html5'       : Relisten HTML5 streaming engine (mobile)
 *   → 'running'|... : GDAR Web Audio API engine (desktop)
 */
(function () {
    'use strict';

    const isMobile =
        /Mobi|Android|iPhone|iPad/i.test(navigator.userAgent) ||
        (navigator.maxTouchPoints > 1 && window.innerWidth < 1024);

    if (isMobile && window._relistenAudio) {
        window._gdarAudio = window._relistenAudio;
        console.log('[Shakedown] Mobile detected → HTML5 streaming engine (Relisten)');
    } else {
        console.log('[Shakedown] Desktop detected → GDAR Web Audio API engine');
        // window._gdarAudio is already set by gapless_audio_engine.js — no-op.
    }

    // Expose detection result for diagnostic purposes.
    window._shakedownAudioStrategy = isMobile ? 'html5' : 'webaudio';
})();
