import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shader Syntax Tests', () {
    test('No duplicate uniforms in .frag files', () {
      Directory root = Directory.current;
      while (root.path != root.parent.path &&
          !File('${root.path}/AGENTS.md').existsSync()) {
        root = root.parent;
      }
      final rootPath = root.path;

      final shaderPaths = [
        '$rootPath/packages/shakedown_core/assets/shaders',
        '$rootPath/packages/styles/gdar_fruit/shaders',
      ];

      final shaderFiles = <File>[];
      for (final path in shaderPaths) {
        final dir = Directory(path);
        if (dir.existsSync()) {
          shaderFiles.addAll(
            dir
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.frag')),
          );
        }
      }

      if (shaderFiles.isEmpty) {
        fail('No shader files found in expected paths: $shaderPaths');
      }

      for (final file in shaderFiles) {
        final content = file.readAsStringSync();
        final lines = content.split('\n');
        final declaredUniforms = <String>{};

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          // Regex to match "uniform type name;"
          // Ignores comments //
          if (line.startsWith('uniform') && !line.startsWith('//')) {
            // Remove comments from the line
            final cleanLine = line.split('//').first.trim();

            // Extract the uniform name
            // uniform float uTime; -> type=float, name=uTime
            final parts = cleanLine.split(RegExp(r'\s+'));
            if (parts.length >= 3) {
              // parts[0] = uniform
              // parts[1] = type (vec2, float, sampler2D)
              // parts[2] = name; (possibly with semicolon)

              String name = parts[2];
              if (name.endsWith(';')) {
                name = name.substring(0, name.length - 1);
              }

              if (declaredUniforms.contains(name)) {
                fail(
                  'Duplicate uniform "$name" found in ${file.uri.pathSegments.last} at line ${i + 1}',
                );
              }
              declaredUniforms.add(name);
            }
          }
        }
      }
    });
  });
}
