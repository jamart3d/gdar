import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/verify_web_build_contracts.dart';

void main() {
  group('findWebBuildContractIssues', () {
    test('returns no issues when all required contracts are present', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'verify_web_build_contracts_test',
      );
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      for (final entry in requiredEngineContracts.entries) {
        final file = File('${tempDir.path}/${entry.key}');
        await file.create(recursive: true);
        await file.writeAsString('// ${entry.value}');
      }

      final issues = findWebBuildContractIssues(tempDir.path);

      expect(issues, isEmpty);
    });

    test('reports missing callback contract in built engine asset', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'verify_web_build_contracts_test',
      );
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });

      for (final entry in requiredEngineContracts.entries) {
        final file = File('${tempDir.path}/${entry.key}');
        await file.create(recursive: true);
        await file.writeAsString('// built asset without required contract');
      }

      final issues = findWebBuildContractIssues(tempDir.path);

      expect(issues, hasLength(requiredEngineContracts.length));
      expect(issues.first, contains('Missing required contract'));
      expect(issues.first, contains('onPlayBlocked'));
    });
  });
}
