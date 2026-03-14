import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shader Syntax Tests', () {
    test('No duplicate uniforms in .frag files', () {
      final shaderDir = Directory('${Directory.current.path}/shaders');
      if (!shaderDir.existsSync()) {
        fail('Shaders directory not found at ${shaderDir.path}');
      }

      final shaderFiles = shaderDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.frag'));

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
                    'Duplicate uniform "$name" found in ${file.uri.pathSegments.last} at line ${i + 1}');
              }
              declaredUniforms.add(name);
            }
          }
        }
      }
    });
  });
}
