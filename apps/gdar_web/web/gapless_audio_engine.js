/**
 * GDAR Gapless Audio Engine (Restored Stable Version)
 * True 0ms gapless playback via Web Audio API AudioBufferSourceNode scheduling.
 * Exposed globally as window._gdarAudio for Dart interop.
 */
(function () {
  'use strict';

  const _log = (window._gdarLogger || console);
  const isBrowser = typeof window !== 'undefined';

  // --- State ----------------------------------------------------------------

  let _ctx = null;          // AudioContext
  let _gainNode = null;     // Master GainNode ? destination
  let _volume = 1.0;

  let _playlist = [];       // [{url, title, artist, album, id}]
  let _currentIndex = -1;
  let _playing = false;
  let _prefetchSeconds = 30;

  // Decoded AudioBuffer cache. Keys = playlist index.
  let _decoded = {};

  // Compressed ArrayBuffer cache. Kept around for seek-back.
  const _compressed = {};

  // AbortControllers for active fetch requests.
  const _abortControllers = {};

  // Active AudioBufferSourceNode for current track.
  let _currentSource = null;
  let _currentTrackStartContextTime = 0;
  let _currentTrackStartOffset = 0;
  let _currentTrackDuration = 0;

  // Pending scheduled source (next track).
  let _scheduledSource = null;
  let _scheduledIndex = -1;
  let _scheduledStartContextTime = 0;

  // Prefetch/Decode state.
  let _fetchingIndex = -1;
  let _prefetchTimer = null;
  let _decodeTimer = null;

  // Position polling (DEPRECATED: Now uses worker ticks)
  // let _positionTimer = null;
  let _workerTickCount = 0;
  const _failedTracks = new Set(); // Static Sentinel: indices that failed to fetch/decode

  // Real-time progress of track buffering (seconds).
  let _currentTrackBufferedSeconds = 0;
  let _nextTrackBufferedSeconds = 0;
  let _isPrefetching = false;
  let _isTransitioning = false;

  // Watchdog.
  let _watchdogTimer = null;
  let _expectedEndContextTime = 0;

  // Processing state communicated to Dart.
  let _loadingState = 'idle';

  // Fetch timing for NET HUD chip (TTFB from archive.org).
  let _fetchStartMs = 0;
  let _fetchInFlight = false;
  let _lastFetchTtfbMs = null;

  // Callbacks registered by Dart.
  let _onStateChange = null;
  let _onTrackChange = null;
  let _onError = null;

  // Safe Logger Utility

  // --- AudioContext Init ----------------------------------------------------

  function _ensureContext() {
    if (_ctx) return;
    const Ctx = window.AudioContext || window.webkitAudioContext;
    if (!Ctx) {
      _emitError('Web Audio API not supported in this browser.');
      return;
    }
    _ctx = new Ctx();
    _gainNode = _ctx.createGain();
    _gainNode.gain.value = _volume;
    _gainNode.connect(_ctx.destination);
    _log.log('[gdar engine] AudioContext created');
  }

  function _registerListeners() {
    if (window._gdarListenersRegistered) return;

    document.addEventListener('click', function _resumeCtx() {
      if (_ctx && _ctx.state === 'suspended') {
        _ctx.resume().catch(() => { });
      }
      if (!_ctx && _playing) {
        _ensureContext();
      }
    }, { capture: true, once: false });

    document.addEventListener('touchstart', function () {
      if (_ctx && _ctx.state === 'suspended') {
        _ctx.resume().catch(() => { });
      }
    }, { capture: true, passive: true });

    window.addEventListener('gdar-worker-tick', _onWorkerTick);

    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'hidden' && _playing) {
        _log.log('[gdar engine] Tab hidden. Recalculating prefetch budget.');
        _schedulePrefetch();
      }
    });

    window._gdarListenersRegistered = true;
    _log.log('[gdar engine] Global listeners registered (including worker ticks)');
  }

  // --- Playlist Management --------------------------------------------------

  function _setPlaylist(tracks, startIndex) {
    _log.log('[gdar engine] setPlaylist', tracks?.length, startIndex);
    _failedTracks.clear();
    _stopCurrentSource();
    _cancelPrefetch();
    _clearScheduled();
    Object.keys(_decoded).forEach(k => delete _decoded[k]);
    Object.keys(_compressed).forEach(k => delete _compressed[k]);
    Object.keys(_abortControllers).forEach(k => {
      try { _abortControllers[k].abort(); } catch (_) { }
      delete _abortControllers[k];
    });

    _playlist = tracks || [];
    _currentIndex = startIndex != null ? startIndex : 0;
    _loadingState = 'idle';
    _playing = false;
    _emitState();
  }

  function _appendTracks(tracks) {
    if (tracks && tracks.length > 0) {
      _playlist = _playlist.concat(tracks);
      _emitState();
    }
  }

  // --- Fetch + Decode Pipeline ----------------------------------------------

  function _fetchCompressed(index) {
    if (_compressed[index]) {
      const track = _playlist[index];
      if (track && _currentIndex + 1 === index) {
        _nextTrackBufferedSeconds = track.duration || 0;
        _emitState();
      }
      return Promise.resolve(_compressed[index]);
    }
    const track = _playlist[index];
    if (!track) return Promise.reject(new Error('No track at index ' + index));

    if (_abortControllers[index]) {
      try { _abortControllers[index].abort(); } catch (_) { }
    }
    const controller = new AbortController();
    _abortControllers[index] = controller;

    _log.log('[gdar engine] Fetching', index, track.url);

    _fetchStartMs = performance.now();
    _fetchInFlight = true;
    _lastFetchTtfbMs = null;
    _emitState();
    return fetch(track.url, { signal: controller.signal })
      .then(async r => {
        _lastFetchTtfbMs = performance.now() - _fetchStartMs;
        _fetchInFlight = false;
        if (!r.ok) {
          _log.error('[gdar engine] Failed to fetch track:', track.url);
          throw new Error('HTTP ' + r.status + ' fetching ' + track.url);
        }

        const contentLength = +r.headers.get('Content-Length');
        const reader = r.body.getReader();
        let receivedLength = 0;
        let chunks = [];

        let lastEmit = 0;
        let chunkCount = 0;

        while (true) {
          const { done, value } = await reader.read();
          if (done) break;
          chunks.push(value);
          receivedLength += value.length;
          chunkCount++;

          // Yield to event loop every 100 chunks to prevent main-thread starvation
          if (chunkCount % 100 === 0) {
            await new Promise(r => setTimeout(r, 0));
          }

          if (_currentIndex === index || _currentIndex + 1 === index) {
            const now = performance.now();
            if (now - lastEmit > 500) { // Throttled to 2Hz for less UI overhead
              const progress = contentLength
                ? (receivedLength / contentLength) * (track.duration || 0)
                : Math.min(track.duration || 0, (receivedLength / 10000000) * (track.duration || 0));

              if (index === _currentIndex) _currentTrackBufferedSeconds = progress;
              else if (index === _currentIndex + 1) _nextTrackBufferedSeconds = progress;

              _emitState();
              lastEmit = now;
            }
          }
        }

        const finalizeStart = performance.now();
        let all = new Uint8Array(receivedLength);
        let pos = 0;
        for (let i = 0; i < chunks.length; i++) {
          const chunk = chunks[i];
          all.set(chunk, pos);
          pos += chunk.length;
          // Yield periodically during large concatenations to avoid UI stalls.
          if (i % 50 === 0) {
            await new Promise(r => setTimeout(r, 0));
          }
        }

        const buf = all.buffer;
        _compressed[index] = buf;

        // Ensure state marks 100% buffer on completion
        if (index === _currentIndex) _currentTrackBufferedSeconds = track.duration || 0;
        if (index === _currentIndex + 1) _nextTrackBufferedSeconds = track.duration || 0;
        _emitState();

        delete _abortControllers[index];
        _log.log(`[gdar engine] Fetch complete for index ${index}. Finalization (buffer concat) took ${(performance.now() - finalizeStart).toFixed(2)}ms`);
        return buf;
      })
      .catch(err => {
        _fetchInFlight = false;
        delete _abortControllers[index];
        if (index === _currentIndex) _currentTrackBufferedSeconds = 0;
        if (index === _currentIndex + 1) _nextTrackBufferedSeconds = 0;
        if (err.name === 'AbortError') return Promise.reject(new Error('Aborted'));
        
        _log.error('[gdar engine] Fetch failed for index', index, err.message);
        _failedTracks.add(index);
        throw err;
      });
  }

  const _decodingPromises = {};

  function _decode(index) {
    if (_decoded[index]) return Promise.resolve(_decoded[index]);
    if (_decodingPromises[index]) {
      _log.log('[gdar engine] Using existing decoding promise for index', index);
      return _decodingPromises[index];
    }
    _ensureContext();

    const p = _fetchCompressed(index).then(compressed => {
      // decodeAudioData detaches the input buffer.
      // We allow it to happen to save a multi-megabyte memory clone.
      return _ctx.decodeAudioData(compressed);
    }).then(audioBuf => {
      _decoded[index] = audioBuf;
      delete _decodingPromises[index];
      // Clean up compressed data after successful decode to save memory
      delete _compressed[index];
      return audioBuf;
    });

    p.catch(err => {
      delete _decodingPromises[index];
      if (err.message !== 'Aborted') {
        _log.error('[gdar engine] Decode failed for index', index, err);
        _failedTracks.add(index);
      }
      throw err;
    });

    _decodingPromises[index] = p;
    return p;
  }

  function _evictOldBuffers() {
    const start = performance.now();
    // In background, be even more aggressive: only keep current and next.
    // (Already doing that, but we can ensure everything else is purged immediately)
    const keep = new Set([_currentIndex, _currentIndex + 1]);
    let count = 0;
    Object.keys(_decoded).forEach(k => {
      if (!keep.has(parseInt(k, 10))) {
        delete _decoded[k];
        count++;
      }
    });
    Object.keys(_compressed).forEach(k => {
      if (!keep.has(parseInt(k, 10))) delete _compressed[k];
    });
    Object.keys(_abortControllers).forEach(k => {
      if (!keep.has(parseInt(k, 10))) {
        try { _abortControllers[k].abort(); } catch (_) { }
        delete _abortControllers[k];
      }
    });
    if (count > 0) {
      _log.log(`[gdar engine] Evicted ${count} old buffers in ${(performance.now() - start).toFixed(2)}ms`);
    }
  }

  // --- Playback -------------------------------------------------------------

  let _startedIndex = -1;
  let _loadingIndex = -1;
  let _lastStartTrackTime = 0;

  function _startTrack(audioBuf, offsetSeconds, startContextTime) {
    const targetIdx = _currentIndex;
    const targetTime = startContextTime != null ? startContextTime : _ctx.currentTime;

    // Guard against starting the same track multiple times if already active
    if (_currentSource && _startedIndex === targetIdx && !startContextTime) {
      _log.log('[gdar engine] Blocked redundant start for active index', targetIdx);
      return;
    }

    // Defensive: if we are already transitioning or loading this exact buffer/offset combo
    // Increase tolerance to 50ms to handle context time drift between rapid calls
    if (_startedIndex === targetIdx && Math.abs(_currentTrackStartContextTime - targetTime) < 0.05) {
      _log.log('[gdar engine] Blocked redundant context-time match for index', targetIdx);
      return;
    }

    // Guard against rapid re-starts (within 100ms) for the same index
    if (_startedIndex === targetIdx && (performance.now() - _lastStartTrackTime) < 100) {
      _log.log('[gdar engine] Blocked rapid re-start for index', targetIdx);
      return;
    }

    _stopCurrentSource();
    _loadingState = 'ready';
    _startedIndex = targetIdx;
    _lastStartTrackTime = performance.now();

    const src = _ctx.createBufferSource();
    src.buffer = audioBuf;
    src.connect(_gainNode);

    _currentTrackDuration = audioBuf.duration;
    _currentTrackStartOffset = offsetSeconds || 0;
    _currentTrackStartContextTime = targetTime;

    _log.log('[gdar engine] Starting track', _currentIndex, 'at', _currentTrackStartContextTime);

    src.start(_currentTrackStartContextTime, _currentTrackStartOffset);
    _expectedEndContextTime = _currentTrackStartContextTime + (_currentTrackDuration - _currentTrackStartOffset);

    src.onended = function () {
      if (_currentSource === src) _onTrackEnded();
    };

    _currentSource = src;
    _playing = true;
    // _startPositionTimer(); // Now handled by global worker tick
    // _startWatchdog();      // Now handled by global worker tick
    _schedulePrefetch();
    _emitState();
    _updateMediaSession();
  }

  function _stopCurrentSource() {
    if (_currentSource) {
      _currentSource.onended = null;
      try { _currentSource.stop(); } catch (_) { }
    _currentSource = null;
    }
    _startedIndex = -1;
    // _stopPositionTimer(); // Now handled by global worker tick
    // _stopWatchdog();      // Now handled by global worker tick
    _expectedEndContextTime = 0;
    // DO NOT clear _decoded here anymore, it breaks instantaneous seeking.
    // Cache is managed via _evictOldBuffers and _setPlaylist.
  }

  function _clearScheduled() {
    if (_scheduledSource) {
      _scheduledSource.onended = null;
      try { _scheduledSource.stop(); } catch (_) { }
      _scheduledSource = null;
    }
    _scheduledIndex = -1;
  }

  function _onTrackEnded() {
    if (_isTransitioning) return;
    _isTransitioning = true;

    const wasIndex = _currentIndex;
    _currentIndex++;

    if (_currentIndex >= _playlist.length) {
      _playing = false;
      _currentSource = null;
      _currentTrackDuration = 0;
      _stopPositionTimer();
      _emitTrackChange(wasIndex, -1);
      _emitState();
      _isTransitioning = false;
      return;
    }

    if (_scheduledSource && _scheduledIndex === _currentIndex) {
      _currentSource = _scheduledSource;
      _scheduledSource = null;
      _scheduledIndex = -1;
      _currentTrackStartOffset = 0;
      _nextTrackBufferedSeconds = 0;

      // CRITICAL FIX: Ensure values are finite to prevent Wasm round() crashes
      _currentTrackDuration = isFinite(_currentSource.buffer.duration) ? _currentSource.buffer.duration : 0;
      _currentTrackStartContextTime = isFinite(_scheduledStartContextTime) ? _scheduledStartContextTime : _ctx.currentTime;
      _expectedEndContextTime = _currentTrackStartContextTime + _currentTrackDuration;

      const activeSrc = _currentSource;
      activeSrc.onended = function () {
        if (_currentSource === activeSrc) _onTrackEnded();
      };

      _playing = true;
      // _startPositionTimer();
      // _startWatchdog();
      _schedulePrefetch();
      _evictOldBuffers();
      _emitTrackChange(wasIndex, _currentIndex);
      _emitState();
      _updateMediaSession();
      _isTransitioning = false;
    } else {
      _stopCurrentSource();
      _currentTrackDuration = 0;
      _nextTrackBufferedSeconds = 0;
      _loadingState = 'loading';
      const targetIndex = _currentIndex;
      _emitTrackChange(wasIndex, _currentIndex);
      _emitState();
      setTimeout(() => {
        _decode(_currentIndex).then(buf => {
          _isTransitioning = false;
          if (_currentIndex === targetIndex) {
            _startTrack(buf, 0, null);
          }
        }).catch(err => {
          _isTransitioning = false;
          _emitError('Decode error: ' + err.message);
        });
      }, 0);
    }
  }

  function _schedulePrefetch() {
    _cancelPrefetch();
    const nextIndex = _currentIndex + 1;
    if (nextIndex >= _playlist.length) return;
    if (_failedTracks.has(nextIndex)) {
      _log.warn('[gdar engine] Sentinel: Skipping prefetch for known failed track:', nextIndex);
      return;
    }

    const remaining = _getRemainingSeconds();
    if (remaining <= 0) return;

    // Use adaptive depth: 30s for foreground, 90s for background
    const depth = document.visibilityState === 'hidden' ? 90 : _prefetchSeconds;

    const fetchIn = Math.max(0, (remaining - (depth + 2)) * 1000);
    const decodeIn = Math.max(0, (remaining - depth) * 1000);

    const timeSinceStart = performance.now() - _lastStartTrackTime;
    const settleDelay = Math.max(0, 2000 - timeSinceStart);

    _prefetchTimer = setTimeout(() => {
      _isPrefetching = true;
      _fetchCompressed(nextIndex).catch(() => { });
      _emitState();
    }, fetchIn + settleDelay);

    _decodeTimer = setTimeout(() => {
      _fetchAndScheduleNext(nextIndex);
    }, decodeIn + settleDelay);
  }

  function _cancelPrefetch() {
    if (_prefetchTimer) { clearTimeout(_prefetchTimer); _prefetchTimer = null; }
    if (_decodeTimer) { clearTimeout(_decodeTimer); _decodeTimer = null; }
    _fetchingIndex = -1;
    _isPrefetching = false;

    // Abort ongoing fetch requests EXCEPT for the next track prefetch if it's already valid.
    // This prevents race conditions during hybrid handoffs where starting track N
    // inadvertently kills the prefetch of N+1 that was already underway.
    const nextIndex = _currentIndex + 1;
    Object.keys(_abortControllers).forEach(indexStr => {
      const index = parseInt(indexStr, 10);
      if (index === nextIndex) return;

      try {
        _log.log('[gdar engine] Aborting orphaned fetch for index', index);
        _abortControllers[index].abort();
      } catch (_) { }
      delete _abortControllers[index];
    });
  }

  function _fetchAndScheduleNext(nextIndex) {
    if (_fetchingIndex === nextIndex) return;
    _fetchingIndex = nextIndex;

    _decode(nextIndex).then(buf => {
      if (!_playing || _currentIndex + 1 !== nextIndex) return;
      const remaining = _getRemainingSeconds();
      const endTime = _ctx.currentTime + remaining;
      const src = _ctx.createBufferSource();
      src.buffer = buf;
      src.connect(_gainNode);
      src.start(endTime, 0);
      _clearScheduled();
      _scheduledSource = src;
      _scheduledIndex = nextIndex;
      _scheduledStartContextTime = endTime;
      _emitState();
    }).catch(err => {
      _log.error('Prefetch error:', err);
    });
  }

  function _getCurrentPositionSeconds() {
    if (!_ctx || !_playing) return _currentTrackStartOffset;
    const elapsed = _ctx.currentTime - _currentTrackStartContextTime;
    return Math.min(_currentTrackStartOffset + elapsed, _currentTrackDuration);
  }

  function _getRemainingSeconds() {
    return Math.max(0, _currentTrackDuration - _getCurrentPositionSeconds());
  }

  function _onWorkerTick() {
    if (!_playing) return;

    // Boundary Sentinel: If we are close to the end (T-15s) and NOTHING is scheduled,
    // force a prefetch check. This handles cases where initial timers were clamped or missed.
    const remaining = _getRemainingSeconds();
    if (remaining < 15 && remaining > 0 && !_scheduledSource && !_isPrefetching && _loadingState !== 'loading' && (_currentIndex + 1 < _playlist.length)) {
      if (!_failedTracks.has(_currentIndex + 1)) {
        _log.warn('[gdar engine] Boundary Sentinel: Next track NOT scheduled at T-15s. Forcing prefetch.');
        _schedulePrefetch();
      }
    }

    // 4Hz tick - Position update
    _emitState();

    // 2Hz (every 2 ticks) - Watchdog
    _workerTickCount++;
    if (_workerTickCount % 2 === 0) {
      _checkWatchdog();
    }
  }

  function _startPositionTimer() {
    // Deprecated in favor of _onWorkerTick
  }

  function _stopPositionTimer() {
    // Deprecated in favor of _onWorkerTick
  }

  function _startWatchdog() {
    // Deprecated in favor of _onWorkerTick
  }

  function _stopWatchdog() {
    // Deprecated in favor of _onWorkerTick
  }

  function _checkWatchdog() {
    if (!_playing || !_ctx || _currentIndex < 0) return;
    if (_expectedEndContextTime <= 0) return;
    if (_ctx.currentTime > _expectedEndContextTime + 0.5) {
      _log.warn('[gdar engine] Watchdog detected missed ending');
      const missedSrc = _currentSource;
      if (missedSrc) {
        missedSrc.onended = null;
        try { missedSrc.stop(); } catch (_) { }
        try { missedSrc.disconnect(); } catch (_) { }
      }
      _currentSource = null;
      _stopWatchdog();
      _expectedEndContextTime = 0;
      _onTrackEnded();
    }
  }

  function _emitState() {
    if (_onStateChange) {
      try {
        let ps = _loadingState;
        if (!_ctx) ps = 'idle';
        else if (_currentIndex < 0) ps = 'idle';

        let nextBuf = 0;
        let nextTotal = 0;

        const currentPos = _getCurrentPositionSeconds();
        const timeRemaining = _currentTrackDuration - currentPos;

        let currentBuf = _currentTrackBufferedSeconds || 0;
        if (_decoded[_currentIndex]) currentBuf = _currentTrackDuration;
        // Safety: Buffer cannot be less than position
        currentBuf = Math.max(currentBuf, currentPos);

        // Message Audit: Emits real-time fetch progress as nextTrackBuffered.
        // We now report prefetch progress as soon as it starts, regardless of time remaining.
        if (_isPrefetching || _fetchingIndex === (_currentIndex + 1)) {
          nextBuf = _nextTrackBufferedSeconds;
          const nextTrack = _playlist[_currentIndex + 1];
          if (nextTrack) nextTotal = nextTrack.duration || 0;
        }

        if (_scheduledSource && _scheduledIndex === (_currentIndex + 1)) {
          nextBuf = _scheduledSource.buffer.duration;
          nextTotal = nextBuf;
        }

        _onStateChange({
          playing: _playing,
          index: _currentIndex,
          position: currentPos,
          duration: _currentTrackDuration,
          currentTrackBuffered: currentBuf,
          nextTrackBuffered: nextBuf,
          nextTrackTotal: nextTotal,
          playlistLength: _playlist.length,
          processingState: ps,
          heartbeatNeeded: window._gdarIsHeartbeatNeeded(),
          heartbeatActive: (function () {
            if (document.visibilityState === 'visible' && _playing) return true;
            return window._gdarHeartbeat ? window._gdarHeartbeat.isActive() : false;
          })(),
          contextState: (function() {
             const hbNeeded = window._gdarIsHeartbeatNeeded();
             const base = _ctx ? (_ctx.state === 'running' || _ctx.state === 'suspended' ? _ctx.state + ' (WA)' : _ctx.state) : 'none';
             return base + (hbNeeded ? ' [HBN]' : ' [HBO]') + ' v1.1.hb';
          })(),
          fetchTtfbMs: _lastFetchTtfbMs,
          fetchInFlight: _fetchInFlight,
        });

        // Update MediaSession Position State
        if (window._gdarMediaSession) {
          window._gdarMediaSession.updatePositionState({
            duration: _currentTrackDuration,
            position: currentPos,
            playing: _playing
          });
        }
      } catch (_) { }
    }
  }

  function _emitTrackChange(from, to) {
    if (_onTrackChange) {
      try { _onTrackChange({ from: from, to: to }); } catch (_) { }
    }
  }

  function _emitError(msg) {
    if (msg && (msg.includes('Aborted') || msg.includes('AbortError') || msg.includes('Failed to fetch'))) {
      _log.log('[gdar engine] Silencing intended abort/noise error:', msg);
      return;
    }
    _log.error('[gdar engine]', msg);
    if (_onError) {
      try { _onError({ message: msg }); } catch (_) { }
    }
  }

  let _mediaSessionRegistered = false;

  function _registerMediaSessionHandlers() {
    if (_mediaSessionRegistered) return;
    if (window._gdarMediaSession) {
      window._gdarMediaSession.setActionHandlers({
        onPlay: () => api.play(),
        onPause: () => api.pause(),
        onNext: () => api.seekToIndex(_currentIndex + 1),
        onPrevious: () => api.seekToIndex(_currentIndex - 1),
        onSeekTo: (e) => api.seek(e.seekTime)
      });
    }
    _mediaSessionRegistered = true;
  }

  function _updateMediaSession() {
    if (!window._gdarMediaSession) return;
    _registerMediaSessionHandlers();
    const track = _playlist[_currentIndex];
    if (track) {
      window._gdarMediaSession.updateMetadata({
        title: track.title,
        artist: track.artist,
        album: track.album
      });
    }
    window._gdarMediaSession.updatePlaybackState(_playing);
  }

  const api = {
    engineType: 'Web Audio (Gapless)',

    init: function () {
      _registerListeners();
      _ensureContext();
    },

    syncState: function (index, position, shouldPlay) {
      _log.log('[gdar engine] syncState', index, position, shouldPlay);
      _currentIndex = index;
      _currentTrackStartOffset = position;
      _playing = shouldPlay;
      if (shouldPlay) this.play();
      else _emitState();
    },

    prepareToPlay: function (index) {
      _log.log('[gdar engine] prepareToPlay', index);
      return _decode(index);
    },

    setPlaylist: function (tracks, startIndex) {
      _setPlaylist(tracks, startIndex);
    },

    appendTracks: function (tracks) {
      _appendTracks(tracks);
    },

    play: function () {
      _ensureContext();
      _playing = true; // Set playback intent early so resume callback triggers api.play() again
      _updateMediaSession();

      if (_ctx.state === 'suspended') {
        if (!_ctx._isResuming) {
          _ctx._isResuming = true;
          _ctx.resume().then(() => {
            _ctx._isResuming = false;
            if (_playing) api.play();
          }).catch(err => {
            _ctx._isResuming = false;
            _log.error('[gdar engine] AudioContext resume failed (potential autoplay block):', err);
          });
        }
        return;
      }

      const index = Math.max(0, _currentIndex);
      if (_playing && _currentSource && _currentIndex === index) return;
      if (_loadingIndex === index && _loadingState === 'loading') {
        _log.log('[gdar engine] Play ignored: already loading index', index);
        return;
      }

      _currentIndex = index;
      _loadingIndex = index;
      _loadingState = 'loading';
      _emitState();

      _decode(index).then(buf => {
        // RACE CONDITION GUARD: If user clicked Pause or Skipped while the fetch/decode 
        // was pending, we MUST NOT call _startTrack. 
        if (!_playing || _currentIndex !== index) {
          _log.log(`[gdar engine] Play aborted: _playing=${_playing}, currentIdx=${_currentIndex}, targetIdx=${index}`);
          _loadingIndex = -1;
          _loadingState = 'idle';
          _emitState();
          return;
        }
        _loadingIndex = -1;
        _startTrack(buf, _currentTrackStartOffset, null);
        _emitTrackChange(-1, index);
      }).catch(err => {
        _loadingIndex = -1;
        _loadingState = 'idle';
        _emitError('Decode error: ' + err.message);
        _emitState();
      });
    },

    _decode: function (index) {
      if (_decoded[index]) return Promise.resolve(_decoded[index]);
      if (_isPureWebAudio && _isPureWebAudio()) {
        // Optimization: If we are in pure mode, we can pre-evict more aggressively
        _evictOldBuffers();
      }

      return _fetchCompressed(index).then(compressed => {
        const decodeStart = performance.now();
        return _ctx.decodeAudioData(compressed).then(decoded => {
          _log.log(`[gdar engine] Decode complete for index ${index} in ${(performance.now() - decodeStart).toFixed(2)}ms`);
          _decoded[index] = decoded;
          return decoded;
        });
      })
        .catch(err => {
          _log.error(`[gdar engine] Decode FAILED for index ${index}:`, err.message);
          throw err;
        });
    },

    pause: function () {
      if (!_ctx || !_playing) return;
      _currentTrackStartOffset = _getCurrentPositionSeconds();
      _playing = false;
      _updateMediaSession();
      _ctx.suspend().then(() => {
        _stopPositionTimer();
        _stopCurrentSource();
        _clearScheduled();
        _cancelPrefetch();
        _emitState();
      });
    },

    stop: function () {
      _stopCurrentSource();
      _clearScheduled();
      _cancelPrefetch();
      _playing = false;
      _loadingState = 'idle';
      _currentTrackDuration = 0;
      _currentTrackBufferedSeconds = 0;
      _nextTrackBufferedSeconds = 0;
      Object.keys(_abortControllers).forEach(k => {
        try { _abortControllers[k].abort(); } catch (_) { }
        delete _abortControllers[k];
      });
      _emitState();
      _updateMediaSession();
    },

    seek: function (seconds) {
      if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;
      const wasPlaying = _playing;
      _stopCurrentSource();
      _clearScheduled();
      _cancelPrefetch();
      _currentTrackStartOffset = seconds;
      if (wasPlaying) {
        _loadingState = 'loading';
        _emitState();
        _decode(_currentIndex).then(buf => {
          _startTrack(buf, seconds, null);
        }).catch(err => _emitError('Seek error: ' + err.message));
      } else {
        _emitState();
      }
    },

    seekToIndex: function (index) {
      if (index < 0 || index >= _playlist.length) return;
      const wasPlaying = _playing;
      const oldIndex = _currentIndex;
      _stopCurrentSource();
      _clearScheduled();
      _cancelPrefetch();
      _currentIndex = index;
      _currentTrackStartOffset = 0;
      _evictOldBuffers();
      if (wasPlaying || _loadingState === 'loading') {
        _loadingState = 'loading';
        _emitState();
        _decode(index).then(buf => {
          if (_currentIndex !== index) return;
          _startTrack(buf, 0, null);
          _emitTrackChange(oldIndex, index);
        }).catch(err => _emitError('SeekToIndex error: ' + err.message));
      } else {
        _emitTrackChange(oldIndex, index);
        _emitState();
      }
    },

    setPrefetchSeconds: function (s) {
      _prefetchSeconds = Math.max(5, Math.min(120, s));
    },

    setVolume: function (v) {
      const next = Math.max(0, Math.min(1, Number(v) || 0));
      _volume = next;
      if (_gainNode) _gainNode.gain.value = _volume;
    },

    getState: function () {
      const ps = _loadingState;
      return {
        playing: _playing,
        index: _currentIndex,
        position: isFinite(_getCurrentPositionSeconds()) ? _getCurrentPositionSeconds() : 0,
        duration: isFinite(_currentTrackDuration) ? _currentTrackDuration : 0,
        currentTrackBuffered: isFinite(_currentTrackDuration) ? _currentTrackDuration : 0,
        nextTrackBuffered: isFinite(_nextTrackBufferedSeconds) ? _nextTrackBufferedSeconds : (_scheduledSource && isFinite(_scheduledSource.buffer.duration) ? _scheduledSource.buffer.duration : 0),
        nextTrackTotal: (_playlist[_currentIndex + 1] && isFinite(_playlist[_currentIndex + 1].duration) ? _playlist[_currentIndex + 1].duration : 0) || (_scheduledSource && isFinite(_scheduledSource.buffer.duration) ? _scheduledSource.buffer.duration : 0),
        playlistLength: _playlist.length,
        processingState: ps,
        heartbeatActive: (function () {
          if (document.visibilityState === 'visible' && _playing) return true;
          return window._gdarHeartbeat ? window._gdarHeartbeat.isActive() : false;
        })(),
        heartbeatNeeded: window._gdarIsHeartbeatNeeded(),
        contextState: (function() {
            const hbNeeded = window._gdarIsHeartbeatNeeded();
            const base = _ctx ? _ctx.state : 'none';
            return base + (hbNeeded ? ' [HBN]' : ' [HBO]');
        })(),
      };
    },

    onStateChange: function (cb) { _onStateChange = cb; },
    onTrackChange: function (cb) { _onTrackChange = cb; },
    onError: function (cb) { _onError = cb; },
  };

  window._gdarAudio = api;
})();







