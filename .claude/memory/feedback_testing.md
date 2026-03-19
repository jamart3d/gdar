---
name: Testing Patterns and Gotchas
description: Non-obvious testing constraints in this codebase
type: feedback
---

Provider fakes use `dynamic noSuchMethod(Invocation inv) => super.noSuchMethod(inv)` — this is the standard pattern. Fakes implement the provider as an interface.

**Dart extension methods break fakes.** Extension dispatch is static — extensions on a provider type run against the fake's missing private fields and throw. Do NOT use extensions to split providers. Use separate classes or mixins.

`ThemeStyle` enum has exactly two values: `android` and `fruit`. There is no `classic`.

`verify_data_integrity_test.dart` always fails locally — it requires the 8MB data asset that isn't present in the test environment. This is a known pre-existing failure, not a regression.

`kIsWeb` is a compile-time constant — web-specific SettingsProvider branches cannot be unit tested. Browser integration tests are needed for those paths.

TV defaults in unit tests: pass `isTv: true` to `SettingsProvider(prefs, isTv: true)`.

**Why:** Learned through test failures during the 2026-03-19 session.
**How to apply:** Before writing tests, check these constraints. Before splitting providers with extensions, don't — use mixins or separate classes.
