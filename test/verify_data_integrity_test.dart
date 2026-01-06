import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdar/models/show.dart';

import 'package:flutter/foundation.dart';

void main() {
  test('Verify output.optimized_src.json integrity and parsing', () async {
    final file = File('assets/data/output.optimized_src.json');
    if (!await file.exists()) {
      fail('assets/data/output.optimized_src.json not found');
    }

    final jsonString = await file.readAsString();
    final List<dynamic> jsonList = json.decode(jsonString);

    debugPrint('Found ${jsonList.length} shows in JSON.');

    int successCount = 0;

    for (var i = 0; i < jsonList.length; i++) {
      final jsonItem = jsonList[i] as Map<String, dynamic>;
      try {
        final show = Show.fromJson(jsonItem);

        // Basic assertions
        expect(show.name, isNotEmpty, reason: 'Show name should not be empty');
        expect(show.venue, isNotEmpty, reason: 'Venue should not be empty');
        expect(show.date, isNotEmpty, reason: 'Date should not be empty');

        // Allow for "Venue at Location" if the user wants strictly no " at " we can check
        // But currently just verifying it doesn't CRASH.

        successCount++;
      } catch (e) {
        fail('Failed to parse show at index $i: $jsonItem\nError: $e');
      }
    }

    debugPrint('Successfully parsed $successCount shows.');
    expect(successCount, equals(jsonList.length));
  });
}
