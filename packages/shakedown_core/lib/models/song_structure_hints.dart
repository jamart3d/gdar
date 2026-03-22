class SongStructureHintCatalog {
  final int version;
  final String kind;
  final String? notes;
  final List<SongStructureHintEntry> entries;

  const SongStructureHintCatalog({
    required this.version,
    required this.kind,
    required this.entries,
    this.notes,
  });

  factory SongStructureHintCatalog.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'];
    return SongStructureHintCatalog(
      version: (json['version'] as num?)?.toInt() ?? 1,
      kind: json['kind'] as String? ?? 'song_structure_hints',
      notes: json['notes'] as String?,
      entries: rawEntries is List
          ? rawEntries
                .whereType<Map>()
                .map(
                  (entry) => SongStructureHintEntry.fromJson(
                    Map<String, dynamic>.from(entry),
                  ),
                )
                .toList()
          : const [],
    );
  }

  SongStructureHintEntry? entryById(String id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  List<SongStructureHintEntry> lookup(String query) {
    final key = SongStructureHintEntry.normalizeLookupKey(query);
    if (key.isEmpty) return const [];
    return entries.where((entry) => entry.matchKeys.contains(key)).toList();
  }
}

class SongStructureHintEntry {
  final String id;
  final String title;
  final String canonicalTitle;
  final String variant;
  final List<String> aliases;
  final List<String> matchKeys;
  final double confidence;
  final SongTempoHint tempo;
  final SongPulseHint pulse;
  final SongRhythmHint rhythm;
  final List<SongSectionHint> sections;
  final SongDetectorHint detectorHints;

  const SongStructureHintEntry({
    required this.id,
    required this.title,
    required this.canonicalTitle,
    required this.variant,
    required this.aliases,
    required this.matchKeys,
    required this.confidence,
    required this.tempo,
    required this.pulse,
    required this.rhythm,
    required this.sections,
    required this.detectorHints,
  });

  factory SongStructureHintEntry.fromJson(Map<String, dynamic> json) {
    return SongStructureHintEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      canonicalTitle: json['canonical_title'] as String? ?? '',
      variant: json['variant'] as String? ?? 'main',
      aliases: _stringList(json['aliases']),
      matchKeys: _stringList(json['match_keys']),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      tempo: SongTempoHint.fromJson(_map(json['tempo'])),
      pulse: SongPulseHint.fromJson(_map(json['pulse'])),
      rhythm: SongRhythmHint.fromJson(_map(json['rhythm'])),
      sections: _list(
        json['sections'],
      ).map((section) => SongSectionHint.fromJson(section)).toList(),
      detectorHints: SongDetectorHint.fromJson(_map(json['detector_hints'])),
    );
  }

  static String normalizeLookupKey(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((entry) => _map(entry)).toList();
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList();
  }
}

class SongTempoHint {
  final int bpmMin;
  final int bpmMax;
  final String feel;
  final double swing;

  const SongTempoHint({
    required this.bpmMin,
    required this.bpmMax,
    required this.feel,
    required this.swing,
  });

  factory SongTempoHint.fromJson(Map<String, dynamic> json) {
    return SongTempoHint(
      bpmMin: (json['bpm_min'] as num?)?.toInt() ?? 0,
      bpmMax: (json['bpm_max'] as num?)?.toInt() ?? 0,
      feel: json['feel'] as String? ?? '',
      swing: (json['swing'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SongPulseHint {
  final int beatsPerBar;
  final String subdivision;
  final String beatStrength;
  final String? subdivisionSource;

  const SongPulseHint({
    required this.beatsPerBar,
    required this.subdivision,
    required this.beatStrength,
    this.subdivisionSource,
  });

  factory SongPulseHint.fromJson(Map<String, dynamic> json) {
    return SongPulseHint(
      beatsPerBar: (json['beats_per_bar'] as num?)?.toInt() ?? 0,
      subdivision: json['subdivision'] as String? ?? '',
      beatStrength: json['beat_strength'] as String? ?? '',
      subdivisionSource: json['subdivision_source'] as String?,
    );
  }
}

class SongRhythmHint {
  final String density;
  final String transientProfile;
  final String notes;
  final String? densitySource;

  const SongRhythmHint({
    required this.density,
    required this.transientProfile,
    required this.notes,
    this.densitySource,
  });

  factory SongRhythmHint.fromJson(Map<String, dynamic> json) {
    return SongRhythmHint(
      density: json['density'] as String? ?? '',
      transientProfile: json['transient_profile'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      densitySource: json['density_source'] as String?,
    );
  }
}

class SongSectionHint {
  final String name;
  final String tempoBias;
  final double pulseConfidence;

  const SongSectionHint({
    required this.name,
    required this.tempoBias,
    required this.pulseConfidence,
  });

  factory SongSectionHint.fromJson(Map<String, dynamic> json) {
    return SongSectionHint(
      name: json['name'] as String? ?? '',
      tempoBias: json['tempo_bias'] as String? ?? '',
      pulseConfidence: (json['pulse_confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SongDetectorHint {
  final bool preferPcm;
  final bool preferLowOnsets;
  final bool preferMidOnsets;
  final double phaseLockStrength;
  final String refractoryBias;

  const SongDetectorHint({
    required this.preferPcm,
    required this.preferLowOnsets,
    required this.preferMidOnsets,
    required this.phaseLockStrength,
    required this.refractoryBias,
  });

  factory SongDetectorHint.fromJson(Map<String, dynamic> json) {
    return SongDetectorHint(
      preferPcm: json['prefer_pcm'] as bool? ?? false,
      preferLowOnsets: json['prefer_low_onsets'] as bool? ?? false,
      preferMidOnsets: json['prefer_mid_onsets'] as bool? ?? false,
      phaseLockStrength:
          (json['phase_lock_strength'] as num?)?.toDouble() ?? 0.0,
      refractoryBias: json['refractory_bias'] as String? ?? 'normal',
    );
  }
}
