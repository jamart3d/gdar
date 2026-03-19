---
trigger: localstorage, flush, web, js, storage
policy_domain: Web Storage
---
# localStorage Key Hygiene (Web)

### Key Namespaces
| Prefix / Key | Owner | Notes |
|---|---|---|
| `flutter.*` | SharedPreferences (Dart) | All `SettingsProvider`, `ThemeProvider` etc. prefs |
| `audio_engine_mode` | Raw JS | Engine mode override |
| `allow_hidden_web_audio` | Raw JS | Hidden web audio flag |
| `gdar_web_error_log_v1` | `web_error_logger.js` | Error log buffer |

### Rule: Never Use localStorage.clear()
`localStorage.clear()` wipes **all keys for the entire origin** — including keys written by any other script on the same domain.

Always use targeted removal:
```js
const keysToRemove = Object.keys(localStorage).filter(k =>
    k.startsWith('flutter.') ||
    k === 'audio_engine_mode' ||
    k === 'allow_hidden_web_audio' ||
    k === 'gdar_web_error_log_v1'
);
keysToRemove.forEach(k => localStorage.removeItem(k));
```

### ?flush=true Behavior
`hybrid_init.js` implements a one-per-session flush guard via `sessionStorage('shakedown_flushed')`. The flush removes only the keys listed above. This is the correct implementation — do not revert to `localStorage.clear()`.
