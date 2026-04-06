import 'dart:io';

const _maxSizeKb = 500;
const _largeImageCandidateKb = 250;
const _excludedSegments = {'archive', 'backups', 'build', 'temp'};

void main() {
  final candidatePaths = _collectCandidateDirectories();
  final assetRoots = selectSourceAssetRoots(candidatePaths);

  stdout.writeln('--- GDAR Asset Audit ---');

  if (assetRoots.isEmpty) {
    stdout.writeln('No source asset roots found under apps/ or packages/.');
    return;
  }

  stdout.writeln('Scanning ${assetRoots.length} source asset root(s):');
  for (final assetRoot in assetRoots) {
    stdout.writeln(' - $assetRoot');
  }
  stdout.writeln();

  var totalFiles = 0;
  var totalBytes = 0;
  var overLimitCount = 0;
  var imageCandidateCount = 0;

  for (final assetRoot in assetRoots) {
    final directory = Directory(assetRoot);
    if (!directory.existsSync()) {
      continue;
    }

    for (final entity in directory.listSync(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File) {
        continue;
      }

      final fileSize = entity.lengthSync();
      final sizeKb = fileSize / 1024;
      final normalizedPath = _normalizePath(entity.path);
      final extension = extensionForPath(normalizedPath);

      totalFiles++;
      totalBytes += fileSize;

      if (sizeKb > _maxSizeKb) {
        overLimitCount++;
        stdout.writeln(
          '[large] ${sizeKb.toStringAsFixed(1)} KB - $normalizedPath',
        );
      }

      if (_isConvertibleImage(extension) && sizeKb > _largeImageCandidateKb) {
        imageCandidateCount++;
        stdout.writeln(
          '[image] ${sizeKb.toStringAsFixed(1)} KB - $normalizedPath (consider WebP)',
        );
      }
    }
  }

  stdout.writeln();
  stdout.writeln('--- Summary ---');
  stdout.writeln('Total files scanned: $totalFiles');
  stdout.writeln(
    'Total source asset size: ${(totalBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
  );
  stdout.writeln('Files over $_maxSizeKb KB: $overLimitCount');
  stdout.writeln('Large PNG/JPG candidates: $imageCandidateCount');
  stdout.writeln('Dead-asset detection remains a manual follow-up.');
}

List<String> selectSourceAssetRoots(Iterable<String> candidatePaths) {
  final assetRoots = <String>{};

  for (final candidate in candidatePaths) {
    final normalized = normalizeAssetRoot(candidate);
    if (normalized == null) {
      continue;
    }
    assetRoots.add(normalized);
  }

  final orderedRoots = assetRoots.toList()..sort();
  return orderedRoots;
}

String? normalizeAssetRoot(String path) {
  final normalized = _normalizePath(path);
  final segments = normalized
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList();
  final rootIndex = _workspaceRootIndex(segments);
  if (rootIndex == -1) {
    return null;
  }

  final relativeSegments = segments.sublist(rootIndex);
  if (relativeSegments.last != 'assets') {
    return null;
  }

  if (relativeSegments.any(_excludedSegments.contains)) {
    return null;
  }

  return relativeSegments.join('/');
}

String extensionForPath(String path) {
  final normalized = _normalizePath(path);
  final dotIndex = normalized.lastIndexOf('.');
  if (dotIndex == -1) {
    return '';
  }

  return normalized.substring(dotIndex).toLowerCase();
}

List<String> _collectCandidateDirectories() {
  final candidates = <String>[];

  for (final rootName in const ['apps', 'packages']) {
    final root = Directory(rootName);
    if (!root.existsSync()) {
      continue;
    }

    final pending = <Directory>[root];
    while (pending.isNotEmpty) {
      final directory = pending.removeLast();
      candidates.add(directory.path);

      for (final entity in directory.listSync(followLinks: false)) {
        if (entity is! Directory) {
          continue;
        }

        if (_shouldSkipDirectory(entity.path)) {
          continue;
        }

        pending.add(entity);
      }
    }
  }

  return candidates;
}

bool _isConvertibleImage(String extension) =>
    extension == '.png' || extension == '.jpg' || extension == '.jpeg';

String _normalizePath(String path) => path.replaceAll('\\', '/');

bool _shouldSkipDirectory(String path) {
  final normalized = _normalizePath(path);
  final segments = normalized.split('/').where((segment) => segment.isNotEmpty);
  return segments.any(_excludedSegments.contains);
}

int _workspaceRootIndex(List<String> segments) {
  final appsIndex = segments.indexOf('apps');
  if (appsIndex != -1) {
    return appsIndex;
  }

  return segments.indexOf('packages');
}
