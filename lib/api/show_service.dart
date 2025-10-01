// lib/api/show_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/utils/logger.dart'; // <-- IMPORT THE LOGGER

class ShowService {
  ShowService._privateConstructor();
  static final ShowService instance = ShowService._privateConstructor();

  List<Show>? _shows;

  Future<List<Show>> getShows() async {
    if (_shows != null) {
      return _shows!;
    }

    try {
      final String jsonString = await rootBundle.loadString('assets/data/shows1.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _shows = jsonList.map((jsonItem) => Show.fromJson(jsonItem)).toList();

      logger.i('Successfully loaded and parsed ${_shows!.length} shows.'); // <-- Example of an info log

      return _shows!;

    } catch (e, stackTrace) {
      // Use logger.e() for errors. It provides better formatting and stack traces.
      logger.e('Error loading shows', error: e, stackTrace: stackTrace); // <-- REPLACED PRINT
      return [];
    }
  }
}