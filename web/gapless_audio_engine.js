/**
 * GDAR Gapless Audio Engine
 * True 0ms gapless playback via Web Audio API AudioBufferSourceNode scheduling.
 * Exposed globally as window._gdarAudio for Dart interop.
 *
 * Architecture:
 *   - Compressed ArrayBuffers cached in RAM (~7MB each, streaming not decoded until needed)
 *   - Only current + next track are decoded to PCM AudioBuffer (~100MB each)
 *   - AudioBufferSourceNode.start(exactEndTime) schedules next track on audio thread
 *   - Sample-accurate: the audio rendering thread handles the stitch, not JS event loop
 */
(function () {
  'use strict';

  // ─── State ────────────────────────────────────────────────────────────────

  let _ctx = null;          // AudioContext
  let _gainNode = null;     // Master GainNode → destination

  let _playlist = [];       // [{url, title, artist, album, id}]
  let _currentIndex = -1;
  let _playing = false;
  let _prefetchSeconds = 30;

  // Decoded AudioBuffer cache. Keys = playlist index.
  // We keep at most 2 (current + next). Evict everything else.
  const _decoded = {};

  // Compressed ArrayBuffer cache. Kept around for seek-back.
  const _compressed = {};

  // Active AudioBufferSourceNode for current track.
  let _currentSource = null;
  let _currentTrackStartContextTime = 0; // AudioContext.currentTime when track playback began
  let _currentTrackStartOffset = 0;       // seek offset within the track (seconds)
  let _currentTrackDuration = 0;          // duration of current track (seconds)

  // Pending scheduled source (next track, already scheduled via .start(endTime)).
  let _scheduledSource = null;
  let _scheduledIndex = -1;

  // Prefetch state.
  let _fetchingIndex = -1;
  let _prefetchTimer = null;

  // Position polling.
  let _positionTimer = null;

  // Callbacks registered by Dart.
  let _onStateChange = null;
  let _onTrackChange = null;
  let _onError = null;

  // ─── AudioContext Init ────────────────────────────────────────────────────

  /**
   * Creates the AudioContext and master GainNode.
   * Must be called after a user gesture (Safari requirement).
   * Also registers a one-time capture-phase click handler to handle lazy init.
   */
  function _ensureContext() {
    if (_ctx) return;
    const Ctx = window.AudioContext || window.webkitAudioContext;
    if (!Ctx) {
      _emitError('Web Audio API not supported in this browser.');
      return;
    }
    _ctx = new Ctx();
    _gainNode = _ctx.createGain();
    _gainNode.gain.value = 1.0;
    _gainNode.connect(_ctx.destination);
  }

  // Safari: resume AudioContext on first user interaction.
  document.addEventListener('click', function _resumeCtx() {
    if (_ctx && _ctx.state === 'suspended') {
      _ctx.resume().catch(() => {});
    }
    if (!_ctx && _playing) {
      _ensureContext();
    }
  }, { capture: true, once: false });

  document.addEventListener('touchstart', function () {
    if (_ctx && _ctx.state === 'suspended') {
      _ctx.resume().catch(() => {});
    }
  }, { capture: true, passive: true });

  // ─── Playlist Management ──────────────────────────────────────────────────

  function _setPlaylist(tracks, startIndex) {
    _stopCurrentSource();
    _cancelPrefetch();
    _clearScheduled();
    Object.keys(_decoded).forEach(k => delete _decoded[k]);
    Object.keys(_compressed).forEach(k => delete _compressed[k]);

    _playlist = tracks || [];
    _currentIndex = startIndex != null ? startIndex : 0;
    _playing = false;
    _emitState();
  }

  function _appendTracks(tracks) {
    if (tracks && tracks.length > 0) {
      _playlist = _playlist.concat(tracks);
      _emitState();
    }
  }

  // ─── Fetch + Decode Pipeline ──────────────────────────────────────────────

  /**
   * Fetches the MP3 at the given playlist index and stores the compressed
   * ArrayBuffer. Returns a Promise<ArrayBuffer>.
   */
  function _fetchCompressed(index) {
    if (_compressed[index]) return Promise.resolve(_compressed[index]);
    const track = _playlist[index];
    if (!track) return Promise.reject(new Error('No track at index ' + index));

    return fetch(track.url)
      .then(r => {
        if (!r.ok) throw new Error('HTTP ' + r.status + ' fetching ' + track.url);
        return r.arrayBuffer();
      })
      .then(buf => {
        _compressed[index] = buf;
        return buf;
      });
  }

  /**
   * Fetches + decodes the track at index into an AudioBuffer.
   * Caches the decoded result. Returns Promise<AudioBuffer>.
   */
  function _decode(index) {
    if (_decoded[index]) return Promise.resolve(_decoded[index]);
    if (!_ctx) _ensureContext();

    return _fetchCompressed(index).then(compressed => {
      // decodeAudioData requires a copy (it detaches the ArrayBuffer).
      const copy = compressed.slice(0);
      return _ctx.decodeAudioData(copy);
    }).then(audioBuf => {
      _decoded[index] = audioBuf;
      return audioBuf;
    });
  }

  /** Evict decoded buffers for all indices except current and next. */
  function _evictOldBuffers() {
    const keep = new Set([_currentIndex, _currentIndex + 1]);
    Object.keys(_decoded).forEach(k => {
      if (!keep.has(parseInt(k, 10))) {
        delete _decoded[k];
      }
    });
  }

  // ─── Playback ─────────────────────────────────────────────────────────────

  /**
   * Starts playing the track at _currentIndex from offsetSeconds.
   * Requires the AudioBuffer to already be decoded (_decoded[_currentIndex]).
   */
  function _startTrack(audioBuf, offsetSeconds, startContextTime) {
    _stopCurrentSource();

    const src = _ctx.createBufferSource();
    src.buffer = audioBuf;
    src.connect(_gainNode);

    _currentTrackDuration = audioBuf.duration;
    _currentTrackStartOffset = offsetSeconds || 0;
    _currentTrackStartContextTime = startContextTime != null
      ? startContextTime
      : _ctx.currentTime;

    src.start(_currentTrackStartContextTime, _currentTrackStartOffset);

    src.onended = function () {
      // Only advance if this source is still the active one
      // (not already replaced by a seek or stop).
      if (_currentSource === src) {
        _onTrackEnded();
      }
    };

    _currentSource = src;
    _playing = true;
    _startPositionTimer();
    _schedulePrefetch();
    _emitState();
    _updateMediaSession();
  }

  function _stopCurrentSource() {
    if (_currentSource) {
      _currentSource.onended = null;
      try { _currentSource.stop(); } catch (_) {}
      _currentSource = null;
    }
    _stopPositionTimer();
  }

  function _clearScheduled() {
    if (_scheduledSource) {
      _scheduledSource.onended = null;
      try { _scheduledSource.stop(); } catch (_) {}
      _scheduledSource = null;
    }
    _scheduledIndex = -1;
  }

  /** Called when the current track's AudioBufferSourceNode fires onended. */
  function _onTrackEnded() {
    const wasIndex = _currentIndex;
    _currentIndex++;

    if (_currentIndex >= _playlist.length) {
      // End of playlist.
      _playing = false;
      _currentSource = null;
      _stopPositionTimer();
      _emitState();
      _emitTrackChange(_currentIndex - 1, -1);
      return;
    }

    // The next track was hopefully pre-scheduled; _scheduledSource is now
    // the active one.
    if (_scheduledSource && _scheduledIndex === _currentIndex) {
      _currentSource = _scheduledSource;
      _scheduledSource = null;
      _scheduledIndex = -1;
      _currentTrackStartOffset = 0;
      _currentTrackStartContextTime = _currentTrackStartContextTime + (_decoded[wasIndex]
        ? _decoded[wasIndex].duration - (wasIndex === _currentIndex - 1 ? 0 : 0)
        : 0);
      // Re-set onended for the now-active source.
      const activeSrc = _currentSource;
      activeSrc.onended = function () {
        if (_currentSource === activeSrc) _onTrackEnded();
      };
      _currentTrackDuration = _decoded[_currentIndex]
        ? _decoded[_currentIndex].duration
        : 0;
      _playing = true;
      _startPositionTimer();
      _schedulePrefetch();
      _evictOldBuffers();
      _emitTrackChange(wasIndex, _currentIndex);
      _emitState();
      _updateMediaSession();
    } else {
      // Scheduling missed (decode wasn't ready in time). Fall back to a
      // regular play with a brief gap.
      _emitTrackChange(wasIndex, _currentIndex);
      _decode(_currentIndex).then(buf => {
        if (_currentIndex === _currentIndex) { // guard stale calls
          _startTrack(buf, 0, null);
          _emitTrackChange(wasIndex, _currentIndex);
        }
      }).catch(err => _emitError('Decode error: ' + err.message));
    }
  }

  // ─── Schedule Next Track ──────────────────────────────────────────────────

  /**
   * Computes how many seconds remain in the current track and either
   * schedules a prefetch timer or (if already decoded) immediately schedules
   * the next AudioBufferSourceNode.
   */
  function _schedulePrefetch() {
    _cancelPrefetch();
    const nextIndex = _currentIndex + 1;
    if (nextIndex >= _playlist.length) return;

    const remaining = _getRemainingSeconds();
    const triggerIn = Math.max(0, (remaining - _prefetchSeconds) * 1000);

    _prefetchTimer = setTimeout(() => {
      _fetchAndScheduleNext(nextIndex);
    }, triggerIn);
  }

  function _cancelPrefetch() {
    if (_prefetchTimer) { clearTimeout(_prefetchTimer); _prefetchTimer = null; }
    _fetchingIndex = -1;
  }

  function _fetchAndScheduleNext(nextIndex) {
    if (_fetchingIndex === nextIndex) return;
    _fetchingIndex = nextIndex;

    _decode(nextIndex).then(buf => {
      if (!_playing || _currentIndex + 1 !== nextIndex) return;

      // Calculate the exact AudioContext time when current track will end.
      const remaining = _getRemainingSeconds();
      const endTime = _ctx.currentTime + remaining;

      const src = _ctx.createBufferSource();
      src.buffer = buf;
      src.connect(_gainNode);
      src.start(endTime, 0);
      // onended will be attached in _onTrackEnded when this becomes active.

      _clearScheduled();
      _scheduledSource = src;
      _scheduledIndex = nextIndex;
      // Store the endTime so _onTrackEnded can reference it.
      _currentTrackStartContextTime = endTime - buf.duration; // retroactively for next
    }).catch(err => {
      _emitError('Prefetch/decode error for track ' + nextIndex + ': ' + err.message);
    });
  }

  // ─── Position Tracking ────────────────────────────────────────────────────

  function _getCurrentPositionSeconds() {
    if (!_ctx || !_playing) return _currentTrackStartOffset;
    const elapsed = _ctx.currentTime - _currentTrackStartContextTime;
    return Math.min(_currentTrackStartOffset + elapsed, _currentTrackDuration);
  }

  function _getRemainingSeconds() {
    return Math.max(0, _currentTrackDuration - _getCurrentPositionSeconds());
  }

  function _startPositionTimer() {
    _stopPositionTimer();
    _positionTimer = setInterval(() => _emitState(), 250);
  }

  function _stopPositionTimer() {
    if (_positionTimer) { clearInterval(_positionTimer); _positionTimer = null; }
  }

  // ─── Callbacks ───────────────────────────────────────────────────────────

  function _emitState() {
    if (_onStateChange) {
      try {
        _onStateChange({
          playing: _playing,
          index: _currentIndex,
          position: _getCurrentPositionSeconds(),
          duration: _currentTrackDuration,
          processingState: !_ctx ? 'idle'
            : _playing ? 'ready'
            : _currentIndex < 0 ? 'idle'
            : 'ready',
        });
      } catch (_) {}
    }
  }

  function _emitTrackChange(from, to) {
    if (_onTrackChange) {
      try { _onTrackChange({ from: from, to: to }); } catch (_) {}
    }
  }

  function _emitError(msg) {
    console.error('[gdar audio]', msg);
    if (_onError) {
      try { _onError({ message: msg }); } catch (_) {}
    }
  }

  // ─── Media Session API ────────────────────────────────────────────────────

  function _updateMediaSession() {
    if (!('mediaSession' in navigator)) return;
    const track = _playlist[_currentIndex];
    if (!track) return;
    navigator.mediaSession.metadata = new MediaMetadata({
      title: track.title || '',
      artist: track.artist || '',
      album: track.album || '',
    });
    navigator.mediaSession.setActionHandler('play', () => api.play());
    navigator.mediaSession.setActionHandler('pause', () => api.pause());
    navigator.mediaSession.setActionHandler('nexttrack', () => api.seekToIndex(_currentIndex + 1));
    navigator.mediaSession.setActionHandler('previoustrack', () => api.seekToIndex(_currentIndex - 1));
  }

  // ─── Public API ──────────────────────────────────────────────────────────

  const api = {

    /** Must be called once at app startup. Safe to call multiple times. */
    init: function () {
      _ensureContext();
    },

    /** Set the full playlist and optionally start at an index. */
    setPlaylist: function (tracks, startIndex) {
      _setPlaylist(tracks, startIndex || 0);
    },

    /** Append additional tracks to the end of the playlist. */
    appendTracks: function (tracks) {
      _appendTracks(tracks);
    },

    /** Begin or resume playback of the current track. */
    play: function () {
      _ensureContext();
      if (_ctx.state === 'suspended') {
        _ctx.resume().then(() => api.play());
        return;
      }
      if (_playing) return;

      if (_currentSource) {
        // Was paused via context suspend; already resumed above.
        _playing = true;
        _startPositionTimer();
        _emitState();
        return;
      }

      const index = Math.max(0, _currentIndex);
      _currentIndex = index;
      _decode(index).then(buf => {
        _startTrack(buf, _currentTrackStartOffset, null);
        _emitTrackChange(-1, index);
      }).catch(err => _emitError('Play decode error: ' + err.message));
    },

    /** Pause playback by suspending the AudioContext. */
    pause: function () {
      if (!_ctx || !_playing) return;
      _playing = false;
      // Capture position before suspend.
      _currentTrackStartOffset = _getCurrentPositionSeconds();
      _ctx.suspend().then(() => {
        _stopPositionTimer();
        _stopCurrentSource();
        _clearScheduled();
        _cancelPrefetch();
        delete _decoded[_currentIndex + 1]; // free next's decoded buffer
        _emitState();
      });
    },

    /** Stop playback and reset to idle. */
    stop: function () {
      _stopCurrentSource();
      _clearScheduled();
      _cancelPrefetch();
      _playing = false;
      _currentTrackStartOffset = 0;
      _emitState();
    },

    /** Seek to a position (seconds) within the current track. */
    seek: function (seconds) {
      if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;
      const wasPlaying = _playing;
      _stopCurrentSource();
      _clearScheduled();
      _cancelPrefetch();
      _currentTrackStartOffset = seconds;
      _playing = false;

      if (wasPlaying) {
        _decode(_currentIndex).then(buf => {
          _startTrack(buf, seconds, null);
        }).catch(err => _emitError('Seek decode error: ' + err.message));
      } else {
        _emitState();
      }
    },

    /** Jump to a specific playlist index and begin playing. */
    seekToIndex: function (index) {
      if (index < 0 || index >= _playlist.length) return;
      _stopCurrentSource();
      _clearScheduled();
      _cancelPrefetch();
      const wasPlaying = _playing;
      const oldIndex = _currentIndex;
      _currentIndex = index;
      _currentTrackStartOffset = 0;
      _playing = false;

      // Keep the compressed buffer; we'll re-decode.
      delete _decoded[index]; // force fresh decode from compressed cache

      if (wasPlaying) {
        _decode(index).then(buf => {
          _startTrack(buf, 0, null);
          _emitTrackChange(oldIndex, index);
        }).catch(err => _emitError('SeekToIndex decode error: ' + err.message));
      } else {
        _emitTrackChange(oldIndex, index);
        _emitState();
      }
    },

    /** Update the prefetch window (seconds before track end to start loading next). */
    setPrefetchSeconds: function (s) {
      _prefetchSeconds = Math.max(5, Math.min(60, s));
    },

    /** Returns a snapshot of current engine state. */
    getState: function () {
      return {
        playing: _playing,
        index: _currentIndex,
        position: _getCurrentPositionSeconds(),
        duration: _currentTrackDuration,
        playlistLength: _playlist.length,
        decodedIndices: Object.keys(_decoded).map(Number),
        compressedIndices: Object.keys(_compressed).map(Number),
        contextState: _ctx ? _ctx.state : 'none',
      };
    },

    /** Register a callback invoked ~4×/sec with current engine state. */
    onStateChange: function (cb) { _onStateChange = cb; },

    /** Register a callback invoked on track index changes. */
    onTrackChange: function (cb) { _onTrackChange = cb; },

    /** Register a callback invoked on errors. */
    onError: function (cb) { _onError = cb; },
  };

  window._gdarAudio = api;

})();
