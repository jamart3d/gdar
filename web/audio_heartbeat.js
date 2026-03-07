/**
 * GDAR Audio Heartbeat
 *
 * Plays a tiny, silent, looping base64 audio file using the standard HTML5 <audio> tag.
 * Mobile operating systems (iOS Safari, Android Chrome) strictly throttle or sleep
 * Javascript memory/Web Workers when the screen is off unless there is an active media element playing.
 *
 * By spinning up this silent heartbeat on play, we trick the OS into keeping our background tab fully alive,
 * which in turn keeps the Web Audio API (gapless_audio_engine.js) running at 100% precision.
 */
(function () {
    'use strict';

    // Safe Logger Utility
    const _log = (window._gdarLogger || console);

    // A tiny 0.1s silent WAV file encoded to base64
    const SILENT_WAV_BASE64 = 'data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YQAAAAA=';

    // A tiny, silent, 1x1 black MP4 video (base64)
    const SILENT_MP4_BASE64 = 'data:video/mp4;base64,AAAAHGZ0eXBtcDQyAAAAAG1wNDJpc29tAAAAGGZyZWUAAAAmbWRhdAAAAAAYEAAAAAMAAAEAAAABAAABAQAAAAAAGGF2YzEAbC0AFf9hdmMxAAAAAAMAAAEAAAABAAABAQAAAAAAGGF2YzEAbC0AFf8=';

    let _heartbeatAudio = null;
    let _heartbeatVideo = null;

    function _initAudio() {
        if (!_heartbeatAudio) {
            _heartbeatAudio = new Audio();
            _heartbeatAudio.src = SILENT_WAV_BASE64;
            _heartbeatAudio.loop = true;
            _heartbeatAudio.volume = 0.01;
            _heartbeatAudio.setAttribute('playsinline', '');
            _heartbeatAudio.setAttribute('preload', 'auto');
        }
    }

    function _initVideo() {
        if (!_heartbeatVideo) {
            _heartbeatVideo = document.createElement('video');
            _heartbeatVideo.src = SILENT_MP4_BASE64;
            _heartbeatVideo.loop = true;
            _heartbeatVideo.muted = true;
            _heartbeatVideo.playsInline = true;
            _heartbeatVideo.setAttribute('playsinline', '');
            _heartbeatVideo.setAttribute('webkit-playsinline', '');
            _heartbeatVideo.style.position = 'absolute';
            _heartbeatVideo.style.width = '1px';
            _heartbeatVideo.style.height = '1px';
            _heartbeatVideo.style.opacity = '0.01';
            _heartbeatVideo.style.pointerEvents = 'none';
            document.body.appendChild(_heartbeatVideo);
        }
    }

    const api = {
        startAudioHeartbeat: function () {
            _initAudio();
            if (_heartbeatAudio.paused) {
                _heartbeatAudio.play().catch(err => {
                    _log.log('[gdar heartbeat] Audio prime failed (handled):', err.message);
                });
            }
        },

        startVideoHeartbeat: function () {
            _initVideo();
            if (_heartbeatVideo.paused) {
                _heartbeatVideo.play().then(() => {
                    _log.log('[gdar heartbeat] Video survival heartbeat started.');
                }).catch(err => {
                    _log.log('[gdar heartbeat] Video prime failed (handled):', err.message);
                });
            }
        },

        startHeartbeat: function () {
            this.startAudioHeartbeat();
            this.startVideoHeartbeat();
        },

        stopHeartbeat: function () {
            if (_heartbeatAudio && !_heartbeatAudio.paused) {
                _heartbeatAudio.pause();
            }
            if (_heartbeatVideo && !_heartbeatVideo.paused) {
                _heartbeatVideo.pause();
            }
            _log.log('[gdar heartbeat] All background survival heartbeats stopped.');
        },

        isAudioActive: function () {
            return !!(_heartbeatAudio && !_heartbeatAudio.paused);
        },

        isVideoActive: function () {
            return !!(_heartbeatVideo && !_heartbeatVideo.paused);
        },

        isActive: function () {
            return !!(this.isAudioActive() || this.isVideoActive());
        }
    };

    window._gdarHeartbeat = api;

})();
