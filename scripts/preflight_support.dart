class PreflightOptions {
  const PreflightOptions({
    required this.isRelease,
    required this.forceRun,
    required this.runMelos,
    required this.writeStatus,
    required this.recordStatusOnly,
  });

  final bool isRelease;
  final bool forceRun;
  final bool runMelos;
  final bool writeStatus;
  final bool recordStatusOnly;
}

PreflightOptions parsePreflightOptions(List<String> args) {
  final isRelease = args.contains('--release');
  final preflightOnly = args.contains('--preflight-only');
  final recordStatusOnly = args.contains('--record-pass');

  return PreflightOptions(
    isRelease: isRelease,
    forceRun: !preflightOnly && !recordStatusOnly && args.contains('--force'),
    runMelos: !preflightOnly && !recordStatusOnly,
    writeStatus: recordStatusOnly || !preflightOnly,
    recordStatusOnly: recordStatusOnly,
  );
}

List<String> detectWindowsToolProcesses(
  String tasklistCsv, {
  required int selfPid,
}) {
  final matches = <String>{};

  for (final process in _parseTasklistCsv(tasklistCsv)) {
    final imageName = process.imageName.toLowerCase();
    final isTracked =
        imageName == 'dart.exe' ||
        imageName == 'dartvm.exe' ||
        imageName == 'flutter.exe' ||
        imageName == 'flutter_tester.exe';

    if (!isTracked) {
      continue;
    }

    if (imageName == 'dart.exe' && process.pid == selfPid) {
      continue;
    }

    matches.add(process.imageName);
  }

  final orderedMatches = matches.toList()..sort();
  return orderedMatches;
}

List<_WindowsProcessInfo> _parseTasklistCsv(String csv) {
  final processes = <_WindowsProcessInfo>[];

  for (final rawLine in csv.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('"Image Name"')) {
      continue;
    }

    final fields = _splitCsvLine(line);
    if (fields.length < 2) {
      continue;
    }

    final pid = int.tryParse(fields[1]);
    if (pid == null) {
      continue;
    }

    processes.add(_WindowsProcessInfo(imageName: fields[0], pid: pid));
  }

  return processes;
}

List<String> _splitCsvLine(String line) {
  final fields = <String>[];
  final buffer = StringBuffer();
  var insideQuotes = false;

  for (var index = 0; index < line.length; index++) {
    final char = line[index];

    if (char == '"') {
      insideQuotes = !insideQuotes;
      continue;
    }

    if (char == ',' && !insideQuotes) {
      fields.add(buffer.toString());
      buffer.clear();
      continue;
    }

    buffer.write(char);
  }

  fields.add(buffer.toString());
  return fields;
}

class _WindowsProcessInfo {
  const _WindowsProcessInfo({required this.imageName, required this.pid});

  final String imageName;
  final int pid;
}
