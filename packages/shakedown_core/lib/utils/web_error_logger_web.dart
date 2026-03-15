import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

const String _storageKey = 'gdar_web_error_log_v1';
const int _maxEntries = 200;

void initWebErrorLogger() {
  web.window.addEventListener(
    'error',
    ((web.Event event) {
      if (event.isA<web.ErrorEvent>()) {
        final e = event as web.ErrorEvent;
        final Object error = e.error?.dartify() ?? e.message;
        recordWebError(error, null, context: 'window.onerror');
      } else {
        recordWebError('Unknown error', null, context: 'window.onerror');
      }
    }).toJS,
  );
}

void recordWebError(Object error, StackTrace? stack, {String? context}) {
  final timestamp = DateTime.now().toIso8601String();
  final contextLabel = context == null ? '' : '[$context] ';
  final buffer = StringBuffer()
    ..write(timestamp)
    ..write(' ')
    ..write(contextLabel)
    ..write(error);

  final stackText = stack?.toString() ?? '';
  if (stackText.isNotEmpty) {
    buffer.write('\n');
    buffer.write(stackText);
  }

  final entry = buffer.toString();
  _appendEntry(entry);
  web.console.error(entry.toJS);
}

void flushWebErrorLog() {
  _writeEntries(<String>[]);
}

void _appendEntry(String entry) {
  final entries = _readEntries();
  entries.add(entry);
  if (entries.length > _maxEntries) {
    final overflow = entries.length - _maxEntries;
    entries.removeRange(0, overflow);
  }
  _writeEntries(entries);
}

List<String> _readEntries() {
  try {
    final raw = web.window.localStorage.getItem(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <String>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded.whereType<String>().toList();
    }
  } catch (_) {}
  return <String>[];
}

void _writeEntries(List<String> entries) {
  try {
    web.window.localStorage.setItem(_storageKey, jsonEncode(entries));
  } catch (_) {}
}
