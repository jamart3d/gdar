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
final _singleLineComment = RegExp(r'//.*$', multiLine: true);
final _blockComment = RegExp(r'/\*.*?\*/', dotAll: true);
final _rawTripleSingleString = RegExp(r"r'''[\s\S]*?'''");
final _rawTripleDoubleString = RegExp(r'r"""[\s\S]*?"""');
final _rawSingleString = RegExp(r"r'[^'\n]*'");
final _rawDoubleString = RegExp(r'r"[^"\n]*"');
final _tripleSingleString = RegExp(r"'''[\s\S]*?'''");
final _tripleDoubleString = RegExp(r'"""[\s\S]*?"""');
final _singleString = RegExp(r"'(?:\\.|[^'\\\n])*'");
final _doubleString = RegExp(r'"(?:\\.|[^"\\\n])*"');
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
  String? reportPath;
  var runLabel = 'Scanner snapshot';
  for (final arg in args) {
    if (arg.startsWith('--report=')) {
      reportPath = arg.substring('--report='.length);
    } else if (arg.startsWith('--run-label=')) {
      runLabel = arg.substring('--run-label='.length);
    }
  }
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

  if (reportPath != null) {
    final report = buildReport(
      now: DateTime.now(),
      runLabel: runLabel,
      roots: targetRoots,
      duplicateGroups: duplicateGroups,
      duplicateInstances: duplicateInstances,
      deadCandidates: deadCandidates,
      groups: duplicateBlocks,
      candidates: deadPrivate,
    );
    final reportFile = File(reportPath);
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString(report);
    stdout.writeln('');
    stdout.writeln('Wrote report: ${reportFile.path}');
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

String sanitizeForIdentifierScan(String content) {
  var sanitized = content;
  sanitized = sanitized.replaceAll(_blockComment, ' ');
  sanitized = sanitized.replaceAll(_singleLineComment, ' ');
  sanitized = sanitized.replaceAll(_rawTripleSingleString, ' ');
  sanitized = sanitized.replaceAll(_rawTripleDoubleString, ' ');
  sanitized = sanitized.replaceAll(_rawSingleString, ' ');
  sanitized = sanitized.replaceAll(_rawDoubleString, ' ');
  sanitized = sanitized.replaceAll(_tripleSingleString, ' ');
  sanitized = sanitized.replaceAll(_tripleDoubleString, ' ');
  sanitized = sanitized.replaceAll(_singleString, ' ');
  sanitized = sanitized.replaceAll(_doubleString, ' ');
  return sanitized;
}

bool isPrivateTypeDeclaration(String line, String symbol) {
  final escaped = RegExp.escape(symbol);
  return RegExp(
        // ignore: prefer_interpolation_to_compose_strings
        r'^\s*(?:abstract\s+)?(?:base\s+|sealed\s+|final\s+)?'
                r'(?:class|enum|mixin|typedef)\s+' +
            escaped +
            r'\b',
      ).hasMatch(line) ||
      RegExp(r'^\s*extension\s+type\s+' + escaped + r'\b').hasMatch(line) ||
      RegExp(r'^\s*extension\s+' + escaped + r'\b').hasMatch(line);
}

/// Returns `true` when [line] declares a JS interop / `external` member.
///
/// External declarations have no Dart body and are bound by the platform
/// (JS interop, dart:ffi, dart:io VM natives). Dead-code analysis does not
/// apply to them because the implementation lives outside the analyzed
/// source, so they must be excluded from dead-private candidate lists to
/// avoid false positives on `@JS(...) external ...` anchors.
bool isInteropExternalDeclaration(String line) {
  return RegExp(r'\bexternal\b').hasMatch(line);
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
    final scanContent = sanitizeForIdentifierScan(entry.value.toString());
    for (final match in _identifier.allMatches(scanContent)) {
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
            .allMatches(sanitizeForIdentifierScan(parsed.content))
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
      final declarationText = parsed.lines[declarationLine - 1];
      if (isPrivateTypeDeclaration(declarationText, symbol)) {
        continue;
      }
      if (isInteropExternalDeclaration(declarationText)) {
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

/// Builds the markdown hygiene report from the scanner's findings.
///
/// Sections the scanner cannot populate (Hygiene Score, Analyzer Findings,
/// Suggested Cuts, delta vs prior report) are emitted as `TODO:` stubs so
/// the workflow knows exactly where human review is required.
String buildReport({
  required DateTime now,
  required String runLabel,
  required List<String> roots,
  required int duplicateGroups,
  required int duplicateInstances,
  required int deadCandidates,
  required SplayTreeMap<String, List<DuplicateBlock>> groups,
  required List<DeadCandidate> candidates,
}) {
  final date =
      '${now.year.toString().padLeft(4, "0")}-'
      '${now.month.toString().padLeft(2, "0")}-'
      '${now.day.toString().padLeft(2, "0")}';
  final buf = StringBuffer();
  buf.writeln('# Code Hygiene Report');
  buf.writeln('Date: $date');
  buf.writeln('Run: $runLabel');
  buf.writeln();
  buf.writeln(
    '> Generated by `scripts/code_hygiene_audit.dart`. '
    'Sections marked `TODO:` require manual review.',
  );
  buf.writeln();
  buf.writeln('## Hygiene Score (1-10)');
  buf.writeln('- TODO: fill in after analyzer + manual review.');
  buf.writeln();
  buf.writeln('## Scope');
  for (final root in roots) {
    buf.writeln('- $root/');
  }
  buf.writeln();
  buf.writeln('## Analyzer Findings (Confirmed)');
  buf.writeln('- TODO: run `dart run melos run analyze` and record result.');
  buf.writeln();
  buf.writeln('## Duplicate-Risk Candidates');
  buf.writeln('- Scanner summary:');
  buf.writeln('  - Duplicate block groups: $duplicateGroups');
  buf.writeln('  - Duplicate block instances: $duplicateInstances');
  buf.writeln('  - Dead private candidates: $deadCandidates');
  if (groups.isNotEmpty) {
    buf.writeln('- Top groups:');
    var shown = 0;
    for (final entry in groups.entries) {
      shown++;
      if (shown > 15) {
        break;
      }
      buf.writeln('  - Group $shown (${entry.value.length} copies):');
      for (final block in entry.value.take(4)) {
        buf.writeln(
          '    - `${block.filePath}:${block.startLine}-${block.endLine}`',
        );
      }
      if (entry.value.length > 4) {
        buf.writeln('    - ... (${entry.value.length - 4} more)');
      }
    }
  }
  buf.writeln();
  buf.writeln('## Dead Private Candidates (Scanner Output)');
  if (candidates.isEmpty) {
    buf.writeln('- None.');
  } else {
    final shown = candidates.length > 40 ? 40 : candidates.length;
    buf.writeln('- Top $shown:');
    for (final candidate in candidates.take(40)) {
      buf.writeln(
        '  - `${candidate.filePath}:${candidate.line}` `${candidate.symbol}`',
      );
    }
    if (candidates.length > 40) {
      buf.writeln('  - ... (${candidates.length - 40} more)');
    }
  }
  buf.writeln();
  buf.writeln('## Suggested Cuts');
  buf.writeln('- delete: TODO');
  buf.writeln('- merge: TODO');
  buf.writeln('- extract: TODO');
  buf.writeln();
  buf.writeln('## Notes / False Positives');
  buf.writeln('- Audit command:');
  buf.writeln('  - `dart run scripts/code_hygiene_audit.dart`');
  buf.writeln('- TODO: delta vs prior report.');
  return buf.toString();
}

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
