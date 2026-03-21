/**
 * GDAR MediaSession Manager
 * 
 * Centralizes MediaSession metadata and playbackState updates.
 * Ensures the 'Anchor' remains stable even when underlying engines swap.
 */
(function () {
    'use strict';

    const _log = (window._gdarLogger || console);
    
    // Track the last known state to avoid redundant updates to the browser
    let _lastMetadata = { title: '', artist: '', album: '' };
    let _lastPlaybackState = 'none';

    const api = {
        updateMetadata: function (metadata) {
            if (!('mediaSession' in navigator)) return;
            
            const title = metadata?.title || '';
            const artist = metadata?.artist || '';
            const album = metadata?.album || '';

            if (title === _lastMetadata.title && 
                artist === _lastMetadata.artist && 
                album === _lastMetadata.album) {
                return; // Redundant
            }

            _log.log('[mediasession] Updating metadata:', title);
            navigator.mediaSession.metadata = new MediaMetadata({
                title: title,
                artist: artist,
                album: album,
                // Artwork is handled via generated shaders in the UI, 
                // but we could put a placeholder here if needed.
                artwork: [
                    { src: 'icons/Icon-192.png', sizes: '192x192', type: 'image/png' },
                    { src: 'icons/Icon-512.png', sizes: '512x512', type: 'image/png' },
                ]
            });

            _lastMetadata = { title, artist, album };
        },

        updatePlaybackState: function (playing) {
            if (!('mediaSession' in navigator)) return;

            const state = playing ? 'playing' : 'paused';
            if (state === _lastPlaybackState) return;

            _log.log('[mediasession] Playback state:', state);
            navigator.mediaSession.playbackState = state;
            _lastPlaybackState = state;
        },

        updatePositionState: function (state) {
            if (!('mediaSession' in navigator) || !navigator.mediaSession.setPositionState) return;

            // setPositionState requires duration, position, and playbackRate
            try {
                const duration = state.duration || 0;
                const position = state.position || 0;
                const playing = state.playing || false;

                if (duration > 0 && position >= 0 && position <= duration) {
                    navigator.mediaSession.setPositionState({
                        duration: duration,
                        // playbackRate must be > 0 per spec; pause state is
                        // communicated separately via playbackState, not here.
                        playbackRate: 1.0,
                        position: position
                    });
                }
            } catch (err) {
                // Some browsers might throw if values are slightly out of sync
                // _log.warn('[mediasession] Failed to set position state:', err.message);
            }
        },

        setActionHandlers: function (callbacks) {
            if (!('mediaSession' in navigator)) return;

            const actions = [
                ['play', callbacks.onPlay],
                ['pause', callbacks.onPause],
                ['stop', callbacks.onStop],
                ['seekbackward', callbacks.onSeekBackward],
                ['seekforward', callbacks.onSeekForward],
                ['seekto', callbacks.onSeekTo],
                ['previoustrack', callbacks.onPrevious],
                ['nexttrack', callbacks.onNext],
            ];

            for (const [action, handler] of actions) {
                try {
                    if (handler) {
                        navigator.mediaSession.setActionHandler(action, handler);
                    } else {
                        navigator.mediaSession.setActionHandler(action, null);
                    }
                } catch (err) {
                    _log.warn(`[mediasession] Action handler '${action}' not supported.`);
                }
            }
        }
    };

    window._gdarMediaSession = api;

})();
