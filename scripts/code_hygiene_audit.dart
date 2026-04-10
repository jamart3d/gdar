import 'dart:collection';
import 'dart:convert';
import 'dart:io';

const _defaultRoots = ['apps', 'packages'];
const _excludedDirs = {
  '.git',
  '.dart_tool',
  '.idea',
  '.vscode',
  'build',
  'node_modules',
  'archive',
  'temp',
  'backups',
};

final _identifier = RegExp(r'\b_[A-Za-z]\w*\b');
final _methodStart = RegExp(
  r'^\s*(?!if\b|for\b|while\b|switch\b|catch\b|else\b|try\b|do\b|class\b|enum\b|mixin\b|extension\b|typedef\b)'
  r'[\w<>\[\]\?,\s]+\s+[_A-Za-z]\w*\s*\([^;]*\)\s*(async\s*)?\{',
);

class DuplicateBlock {
  DuplicateBlock({
    required this.filePath,
    required this.startLine,
    required this.endLine,
  });

  final String filePath;
  final int startLine;
  final int endLine;
}

Future<void> main(List<String> args) async {
  final failOnFindings = args.contains('--fail-on-findings');
  final roots = args.where((a) => !a.startsWith('--')).toList();
  final targetRoots = roots.isEmpty ? _defaultRoots : roots;

  final dartFiles = await _collectDartFiles(targetRoots);
  if (dartFiles.isEmpty) {
    stdout.writeln('No Dart files found in ${targetRoots.join(", ")}.');
    exit(0);
  }

  stdout.writeln('Scanning ${dartFiles.length} Dart file(s)...');

  final duplicateBlocks = await _findDuplicateBlocks(dartFiles);
  final deadPrivate = await _findDeadPrivateCandidates(dartFiles);

  final duplicateGroups = duplicateBlocks.length;
  final duplicateInstances = duplicateBlocks.values.fold<int>(
    0,
    (sum, list) => sum + list.length,
  );
  final deadCandidates = deadPrivate.length;

  stdout.writeln('');
  stdout.writeln('Code Hygiene Summary');
  stdout.writeln('- Duplicate block groups: $duplicateGroups');
  stdout.writeln('- Duplicate block instances: $duplicateInstances');
  stdout.writeln('- Dead private candidates: $deadCandidates');

  if (duplicateGroups > 0) {
    stdout.writeln('');
    stdout.writeln('Potential duplicate code (top 15 groups):');
    var shown = 0;
    for (final entry in duplicateBlocks.entries) {
      shown++;
      if (shown > 15) {
        break;
      }
      stdout.writeln('  [$shown] ${entry.value.length} copies');
      for (final block in entry.value.take(4)) {
        stdout.writeln(
          '      - ${block.filePath}:${block.startLine}-${block.endLine}',
        );
      }
      if (entry.value.length > 4) {
        stdout.writeln('      - ... (${entry.value.length - 4} more)');
      }
    }
  }

  if (deadCandidates > 0) {
    stdout.writeln('');
    stdout.writeln('Potential dead private members (top 40):');
    for (final candidate in deadPrivate.take(40)) {
      stdout.writeln(
        '  - ${candidate.filePath}:${candidate.line} ${candidate.symbol}',
      );
    }
    if (deadCandidates > 40) {
      stdout.writeln('  - ... (${deadCandidates - 40} more)');
    }
  }

  final findings = duplicateGroups + deadCandidates;
  if (failOnFindings && findings > 0) {
    exit(2);
  }
}

Future<List<File>> _collectDartFiles(List<String> roots) async {
  final files = <File>[];

  for (final root in roots) {
    final dir = Directory(root);
    if (!await dir.exists()) {
      continue;
    }
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final segments = entity.uri.pathSegments.map((s) => s.toLowerCase());
      if (segments.any(_excludedDirs.contains)) {
        continue;
      }
      files.add(entity);
    }
  }

  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

Future<SplayTreeMap<String, List<DuplicateBlock>>> _findDuplicateBlocks(
  List<File> files,
) async {
  final byFingerprint = <String, List<DuplicateBlock>>{};

  for (final file in files) {
    final normalizedPath = _normalizePath(file.path);
    if (normalizedPath.endsWith('.g.dart')) {
      continue;
    }
    final lines = await file.readAsLines();
    final blocks = _extractMethodBlocks(file.path, lines);
    for (final block in blocks) {
      final list = byFingerprint.putIfAbsent(block.$1, () => []);
      list.add(block.$2);
    }
  }

  final grouped = SplayTreeMap<String, List<DuplicateBlock>>();
  final sorted =
      byFingerprint.entries.where((entry) => entry.value.length > 1).toList()
        ..sort((a, b) => b.value.length.compareTo(a.value.length));

  for (var i = 0; i < sorted.length; i++) {
    grouped['group_${i + 1}'] = sorted[i].value;
  }
  return grouped;
}

List<(String, DuplicateBlock)> _extractMethodBlocks(
  String filePath,
  List<String> lines,
) {
  final blocks = <(String, DuplicateBlock)>[];
  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    if (!_methodStart.hasMatch(line)) {
      i++;
      continue;
    }

    var depth = 0;
    var foundStartBrace = false;
    final start = i;
    var end = i;

    for (var j = i; j < lines.length; j++) {
      final current = lines[j];
      depth += '{'.allMatches(current).length;
      depth -= '}'.allMatches(current).length;
      if (current.contains('{')) {
        foundStartBrace = true;
      }
      if (foundStartBrace && depth <= 0) {
        end = j;
        break;
      }
    }

    final lineCount = end - start + 1;
    if (lineCount >= 6 && lineCount <= 200) {
      final raw = lines.sublist(start, end + 1).join('\n');
      final normalized = _normalizeBlock(raw);
      if (normalized.length >= 120) {
        final digest = base64Url.encode(utf8.encode(normalized));
        blocks.add((
          digest,
          DuplicateBlock(
            filePath: filePath.replaceAll('\\', '/'),
            startLine: start + 1,
            endLine: end + 1,
          ),
        ));
      }
    }

    i = end + 1;
  }
  return blocks;
}

String _normalizeBlock(String input) {
  final noSingleLineComments = input
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');
  final noBlockComments = noSingleLineComments.replaceAll(
    RegExp(r'/\*.*?\*/', dotAll: true),
    '',
  );
  final collapsedWhitespace = noBlockComments.replaceAll(RegExp(r'\s+'), ' ');
  return collapsedWhitespace.trim();
}

class DeadCandidate {
  DeadCandidate({
    required this.filePath,
    required this.line,
    required this.symbol,
  });

  final String filePath;
  final int line;
  final String symbol;
}

class _ParsedDartFile {
  _ParsedDartFile({
    required this.path,
    required this.content,
    required this.lines,
    required this.partUris,
    required this.partOfUri,
    required this.partOfName,
    required this.libraryName,
  });

  final String path;
  final String content;
  final List<String> lines;
  final List<String> partUris;
  final String? partOfUri;
  final String? partOfName;
  final String? libraryName;
}

Future<List<DeadCandidate>> _findDeadPrivateCandidates(List<File> files) async {
  final parsedFiles = <String, _ParsedDartFile>{};
  for (final file in files) {
    final content = await file.readAsString();
    final lines = content.split('\n');
    final path = _normalizePath(file.path);
    parsedFiles[path] = _ParsedDartFile(
      path: path,
      content: content,
      lines: lines,
      partUris: _extractPartUris(content),
      partOfUri: _extractPartOfUri(content),
      partOfName: _extractPartOfName(content),
      libraryName: _extractLibraryName(content),
    );
  }

  final libraryRootsByName = <String, String>{};
  for (final parsed in parsedFiles.values) {
    final libraryName = parsed.libraryName;
    if (libraryName == null) {
      continue;
    }
    libraryRootsByName.putIfAbsent(libraryName, () => parsed.path);
  }

  final rootByFile = <String, String>{};
  for (final parsed in parsedFiles.values) {
    final root = _resolveLibraryRoot(parsed, parsedFiles, libraryRootsByName);
    rootByFile[parsed.path] = root;
  }

  final contentByRoot = <String, StringBuffer>{};
  for (final parsed in parsedFiles.values) {
    final root = rootByFile[parsed.path]!;
    final buffer = contentByRoot.putIfAbsent(root, () => StringBuffer());
    buffer.writeln(parsed.content);
  }

  final symbolUsageByRoot = <String, Map<String, int>>{};
  for (final entry in contentByRoot.entries) {
    final counts = <String, int>{};
    for (final match in _identifier.allMatches(entry.value.toString())) {
      final symbol = match.group(0)!;
      counts.update(symbol, (value) => value + 1, ifAbsent: () => 1);
    }
    symbolUsageByRoot[entry.key] = counts;
  }

  final results = <DeadCandidate>[];

  for (final parsed in parsedFiles.values) {
    final usage = symbolUsageByRoot[rootByFile[parsed.path]] ?? const {};
    final symbols =
        _identifier
            .allMatches(parsed.content)
            .map((m) => m.group(0)!)
            .toSet()
            .where((s) => s.length > 1)
            .toList()
          ..sort();

    if (symbols.isEmpty) {
      continue;
    }

    for (final symbol in symbols) {
      final occurrences = usage[symbol] ?? 0;
      if (occurrences > 1 || occurrences == 0) {
        continue;
      }

      final declarationLine = _findLine(parsed.lines, symbol);
      if (declarationLine == null) {
        continue;
      }
      results.add(
        DeadCandidate(
          filePath: parsed.path,
          line: declarationLine,
          symbol: symbol,
        ),
      );
    }
  }

  results.sort((a, b) {
    final byFile = a.filePath.compareTo(b.filePath);
    if (byFile != 0) {
      return byFile;
    }
    return a.line.compareTo(b.line);
  });
  return results;
}

String _resolveLibraryRoot(
  _ParsedDartFile parsed,
  Map<String, _ParsedDartFile> allFiles,
  Map<String, String> libraryRootsByName,
) {
  if (parsed.partOfUri != null) {
    final parent = File(parsed.path).parent.uri;
    final resolved = _normalizePath(
      parent.resolve(parsed.partOfUri!).toFilePath(),
    );
    if (allFiles.containsKey(resolved)) {
      return resolved;
    }
  }

  if (parsed.partOfName != null) {
    final byName = libraryRootsByName[parsed.partOfName!];
    if (byName != null) {
      return byName;
    }
  }

  if (parsed.partUris.isNotEmpty) {
    return parsed.path;
  }

  return parsed.path;
}

List<String> _extractPartUris(String content) {
  final regex = RegExp(r'''^\s*part\s+['"]([^'"]+)['"]\s*;''', multiLine: true);
  return regex.allMatches(content).map((m) => m.group(1)!).toList();
}

String? _extractPartOfUri(String content) {
  final match = RegExp(
    r'''^\s*part of\s+['"]([^'"]+)['"]\s*;''',
    multiLine: true,
  ).firstMatch(content);
  return match?.group(1);
}

String? _extractPartOfName(String content) {
  final match = RegExp(
    r'^\s*part of\s+([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\s*;',
    multiLine: true,
  ).firstMatch(content);
  return match?.group(1);
}

String? _extractLibraryName(String content) {
  final match = RegExp(
    r'^\s*library\s+([A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*)\s*;',
    multiLine: true,
  ).firstMatch(content);
  return match?.group(1);
}

String _normalizePath(String path) => path.replaceAll('\\', '/');

int? _findLine(List<String> lines, String symbol) {
  final rx = RegExp('\\b${RegExp.escape(symbol)}\\b');
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (!rx.hasMatch(line)) {
      continue;
    }
    if (line.trimLeft().startsWith('//')) {
      continue;
    }
    return i + 1;
  }
  return null;
}
