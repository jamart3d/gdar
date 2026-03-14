(function () {
  const storageKey = 'gdar_web_error_log_v1';
  const maxEntries = 200;

  function readEntries() {
    try {
      const raw = window.localStorage.getItem(storageKey);
      if (!raw) return [];
      const decoded = JSON.parse(raw);
      return Array.isArray(decoded) ? decoded : [];
    } catch (_) {
      return [];
    }
  }

  function writeEntries(entries) {
    try {
      window.localStorage.setItem(storageKey, JSON.stringify(entries));
    } catch (_) {}
  }

  function appendEntry(entry) {
    const entries = readEntries();
    entries.push(entry);
    if (entries.length > maxEntries) {
      entries.splice(0, entries.length - maxEntries);
    }
    writeEntries(entries);
  }

  function normalizeError(error) {
    if (error instanceof Error) {
      return error.stack || error.message || String(error);
    }
    if (typeof error === 'string') {
      return error;
    }
    try {
      return JSON.stringify(error);
    } catch (_) {
      return String(error);
    }
  }

  function recordError(error, stack, context) {
    const timestamp = new Date().toISOString();
    const label = context ? '[' + context + '] ' : '';
    let entry = timestamp + ' ' + label + normalizeError(error);
    if (stack) {
      entry += '\n' + stack;
    }
    appendEntry(entry);
    try {
      console.error(entry);
    } catch (_) {}
  }

  window.gdarDumpErrors = function () {
    const entries = readEntries();
    try {
      entries.forEach((entry) => console.error(entry));
    } catch (_) {}
    return entries;
  };

  window.gdarClearErrors = function () {
    writeEntries([]);
    return true;
  };

  window.gdarRecordError = function (error, stack, context) {
    recordError(error, stack, context);
  };

  window.addEventListener('error', function (event) {
    const err = event.error || event.message || 'Unknown error';
    const stack = event.error && event.error.stack ? event.error.stack : null;
    recordError(err, stack, 'window.onerror');
  });

  window.addEventListener('unhandledrejection', function (event) {
    recordError(event.reason || 'Unhandled rejection', null, 'unhandledrejection');
  });
})();
