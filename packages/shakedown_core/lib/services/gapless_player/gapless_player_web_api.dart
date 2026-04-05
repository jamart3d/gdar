part of 'gapless_player_web.dart';

mixin _GaplessPlayerWebApi on _GaplessPlayerBase, _GaplessPlayerWebEngine {
  _JsTrack _sourceToJsTrack(AudioSource source) {
    if (source is UriAudioSource) {
      final tag = source.tag;
      final item = tag is MediaItem ? tag : null;
      return _JsTrack(
        url: source.uri.toString().toJS,
        title: (item?.title ?? '').toJS,
        artist: (item?.artist ?? '').toJS,
        album: (item?.album ?? '').toJS,
        id: (item?.id ?? '').toJS,
        duration: (item?.duration?.inSeconds.toDouble() ?? 0.0).toJS,
      );
    }
    return _JsTrack(
      url: ''.toJS,
      title: ''.toJS,
      artist: ''.toJS,
      album: ''.toJS,
      id: ''.toJS,
      duration: 0.0.toJS,
    );
  }

  Future<Duration?> setAudioSources(
    List<AudioSource> children, {
    int initialIndex = 0,
    Duration initialPosition = Duration.zero,
    bool preload = true,
  }) async {
    if (!_useJsEngine) {
      return _fallbackPlayer!.setAudioSources(
        children,
        initialIndex: initialIndex,
        initialPosition: initialPosition,
        preload: preload,
      );
    }
    _sequence = children.whereType<IndexedAudioSource>().toList();

    _callEngine((engine) {
      engine.setPlaylist(
        children.map(_sourceToJsTrack).toList().toJS,
        initialIndex.toJS,
      );
      if (initialPosition != Duration.zero) {
        engine.seek((initialPosition.inMilliseconds / 1000.0).toJS);
      }
    });

    _emitSequenceState();
    return null;
  }

  Future<void> addAudioSources(List<AudioSource> sources) async {
    if (!_useJsEngine) {
      return _fallbackPlayer!.addAudioSources(sources);
    }
    _sequence = [..._sequence, ...sources.whereType<IndexedAudioSource>()];
    _callEngine((engine) {
      engine.appendTracks(sources.map(_sourceToJsTrack).toList().toJS);
    });
  }

  Future<void> play() async {
    if (!_useJsEngine) {
      await _fallbackPlayer?.play();
    } else {
      _callEngine((engine) => engine.play());
    }
  }

  Future<void> pause() async {
    if (!_useJsEngine) {
      await _fallbackPlayer?.pause();
    } else {
      _callEngine((engine) => engine.pause());
    }
  }

  Future<void> stop() async {
    if (!_useJsEngine) {
      await _fallbackPlayer?.stop();
    } else {
      _callEngine((engine) => engine.stop());
    }
  }

  Future<void> seek(Duration? position, {int? index}) async {
    if (!_useJsEngine) {
      return _fallbackPlayer?.seek(position, index: index);
    }
    _callEngine((engine) {
      if (index != null) {
        engine.seekToIndex(index.toJS);
      } else if (position != null) {
        engine.seek((position.inMilliseconds / 1000.0).toJS);
      }
    });
  }

  Future<void> setVolume(double volume) async {
    if (!_useJsEngine) {
      await _fallbackPlayer?.setVolume(volume);
    } else {
      _callEngine((engine) {
        final object = _JSObject(engine as JSObject);
        if (object.hasOwnProperty('setVolume'.toJS)) {
          engine.setVolume(volume.toJS);
        }
      });
    }
  }

  Future<void> seekToNext() async {
    if (!_useJsEngine) {
      return _fallbackPlayer?.seekToNext();
    }
    final next = (_currentIndex ?? 0) + 1;
    if (next < _sequence.length) {
      _callEngine((engine) => engine.seekToIndex(next.toJS));
    }
  }

  Future<void> seekToPrevious() async {
    if (!_useJsEngine) {
      return _fallbackPlayer?.seekToPrevious();
    }
    final previous = (_currentIndex ?? 1) - 1;
    if (previous >= 0) {
      _callEngine((engine) => engine.seekToIndex(previous.toJS));
    }
  }

  void setCrossfadeDurationSeconds(double seconds) {
    if (_useJsEngine && _engine != null) {
      final engine = _engine;
      if (engine == null) {
        return;
      }
      final gdar = _GdarAudioEngine(engine);
      gdar.setCrossfadeDurationSeconds(seconds.toJS);
    }
  }

  void setHandoffCrossfadeMs(int milliseconds) {
    if (_useJsEngine) {
      _callEngine((engine) {
        final object = _JSObject(engine as JSObject);
        if (object.hasOwnProperty('setHandoffCrossfadeMs'.toJS)) {
          engine.setHandoffCrossfadeMs(milliseconds.toJS);
        }
      });
    }
  }

  void setWebPrefetchSeconds(int seconds) {
    if (_useJsEngine) {
      _callEngine((engine) => engine.setPrefetchSeconds(seconds.toJS));
    }
  }

  void setHybridBackgroundMode(String mode) {
    if (_useJsEngine) {
      _callEngine((engine) {
        final object = _JSObject(engine as JSObject);
        if (object.hasOwnProperty('setHybridBackgroundMode'.toJS)) {
          engine.setHybridBackgroundMode(mode.toJS);
        }
      });
    }
  }

  void setHybridHandoffMode(String mode) {
    if (_useJsEngine) {
      _callEngine((engine) {
        final object = _JSObject(engine as JSObject);
        if (object.hasOwnProperty('setHybridHandoffMode'.toJS)) {
          engine.setHybridHandoffMode(mode.toJS);
        }
      });
    }
  }

  void setHybridAllowHiddenWebAudio(bool enabled) {
    if (_useJsEngine) {
      _callEngine((engine) {
        final object = _JSObject(engine as JSObject);
        if (object.hasOwnProperty('setHybridAllowHiddenWebAudio'.toJS)) {
          engine.setHybridAllowHiddenWebAudio(enabled.toJS);
        }
      });
    }
  }

  void setTrackTransitionMode(String mode) {
    if (_useJsEngine) {
      final normalized = mode == 'gap' ? 'gap' : 'gapless';
      _callEngine((engine) {
        final object = _JSObject(engine as JSObject);
        if (object.hasOwnProperty('setTrackTransitionMode'.toJS)) {
          engine.setTrackTransitionMode(normalized.toJS);
        }
      });
    }
  }

  Future<void> dispose() async {
    _staleTickTimer?.cancel();
    _staleTickTimer = null;
    if (!_useJsEngine) {
      return _fallbackPlayer?.dispose();
    }
    _callEngine((engine) => engine.stop());
    await _playerStateController.close();
    await _playbackEventController.close();
    await _playingController.close();
    await _processingStateController.close();
    await _engineStateStringController.close();
    await _engineContextStateController.close();
    await _positionController.close();
    await _bufferedPositionController.close();
    await _durationController.close();
    await _indexController.close();
    await _sequenceStateController.close();
    await _nextTrackBufferedController.close();
    await _nextTrackTotalController.close();
    await _heartbeatActiveController.close();
    await _heartbeatNeededController.close();
    await _driftController.close();
    await _visibilityController.close();
  }

  void reload() {
    _reloadPage();
  }
}
