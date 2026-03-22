import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/services/song_structure_hint_service.dart';

void main() {
  test('parses grateful dead song structure hints asset', () async {
    String path =
        'packages/shakedown_core/assets/data/audio/grateful_dead_song_structure_hints.json';
    if (!await File(path).exists()) {
      path = 'assets/data/audio/grateful_dead_song_structure_hints.json';
    }
    final file = File(path);
    if (!await file.exists()) {
      fail('grateful_dead_song_structure_hints.json not found in $path');
    }

    final jsonString = await file.readAsString();
    final catalog = SongStructureHintService.parseCatalog(jsonString);

    expect(catalog.version, 1);
    expect(catalog.kind, 'grateful_dead_song_structure_hints');
    expect(catalog.entries, isNotEmpty);

    final ids = catalog.entries.map((entry) => entry.id).toList();
    expect(ids.toSet().length, ids.length);

    final eyesMatches = catalog.lookup('Eyes');
    expect(eyesMatches, isNotEmpty);
    expect(
      eyesMatches.any((entry) => entry.canonicalTitle == 'Eyes of the World'),
      isTrue,
    );
  });

  test('lookup normalizes punctuation and aliases', () async {
    String path =
        'packages/shakedown_core/assets/data/audio/grateful_dead_song_structure_hints.json';
    if (!await File(path).exists()) {
      path = 'assets/data/audio/grateful_dead_song_structure_hints.json';
    }
    final file = File(path);
    final jsonString = await file.readAsString();
    final catalog = SongStructureHintService.parseCatalog(jsonString);

    final matches = catalog.lookup("He's Gone");
    expect(matches, isNotEmpty);
    expect(matches.first.id, isNotEmpty);
    expect(matches.first.matchKeys, contains('he_s_gone'));
  });
}
