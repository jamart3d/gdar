import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shakedown_core/models/song_structure_hints.dart';
import 'package:shakedown_core/utils/asset_constants.dart';

class SongStructureHintService {
  const SongStructureHintService();

  static SongStructureHintCatalog parseCatalog(String jsonString) {
    final decoded = jsonDecode(jsonString);
    if (decoded is! Map) {
      throw const FormatException(
        'Song structure hints JSON must be a top-level object.',
      );
    }
    return SongStructureHintCatalog.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  Future<SongStructureHintCatalog> loadCatalog({AssetBundle? bundle}) async {
    final jsonString = await (bundle ?? rootBundle).loadString(
      AssetConstants.gratefulDeadSongStructureHintsJson,
    );
    return parseCatalog(jsonString);
  }
}
