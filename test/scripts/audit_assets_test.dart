import 'package:flutter_test/flutter_test.dart';

import '../../scripts/size_guard/audit_assets.dart';

void main() {
  group('selectSourceAssetRoots', () {
    test('keeps package and app asset roots and ignores build output', () {
      final roots = selectSourceAssetRoots([
        r'packages\shakedown_core\assets',
        r'packages\gdar_design\assets',
        r'apps\gdar_mobile\build\flutter_assets\packages\shakedown_core\assets',
        r'apps\gdar_web\assets',
        r'assets',
      ]);

      expect(roots, <String>[
        'apps/gdar_web/assets',
        'packages/gdar_design/assets',
        'packages/shakedown_core/assets',
      ]);
    });

    test('ignores archive, temp, and backup asset roots', () {
      final roots = selectSourceAssetRoots([
        'packages/shakedown_core/assets',
        'packages/archive/legacy/assets',
        'packages/temp/scratch/assets',
        'packages/backups/old/assets',
      ]);

      expect(roots, <String>['packages/shakedown_core/assets']);
    });
  });
}
