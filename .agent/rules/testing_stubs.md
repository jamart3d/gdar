# Testing Stubs & Helpers

### 1. Preferred Pattern: Interface Fakes with noSuchMethod
The codebase standard is **fake classes** that implement the provider interface, not Mockito mocks:

```dart
class _FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  bool get performanceMode => false;
  @override
  bool get useTrueBlack => false;
  // ... only override what the test actually needs ...

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

`noSuchMethod` handles everything not explicitly overridden. This avoids `MissingStubError` without requiring every method to be stubbed.

### 2. Critical: Extension Methods Break Fakes
Dart extension methods dispatch **statically** — they run against the compile-time type, not the runtime type. If `SettingsProvider` has extension methods (e.g., for a split-out group of getters), those extensions will execute on the fake and try to access private fields the fake doesn't have, causing a runtime throw.

**Do NOT use Dart extension methods to split providers.** Use separate classes or mixins.

### 3. ThemeStyle Enum
`ThemeStyle` has exactly **two** values: `android` and `fruit`. There is no `classic`. Using `ThemeStyle.classic` will not compile.

### 4. kIsWeb is Compile-Time
`kIsWeb` is a compile-time constant, always `false` in unit tests. Web-specific branches in `SettingsProvider` (`kIsWeb` guards) cannot be exercised by unit tests. Browser integration tests are required for those paths. Document this limitation in test files rather than fighting it.

### 5. TV Defaults in Tests
Pass `isTv: true` to the `SettingsProvider` constructor to exercise TV defaults:
```dart
final provider = SettingsProvider(prefs, isTv: true);
```

### 6. Known Pre-Existing Failure
`verify_data_integrity_test.dart` always fails locally — it requires the 8MB data asset which is absent from the test environment. This is not a regression; ignore it in local runs.

### 7. Required Providers in Widget Tests
When testing a widget that uses `FruitTabBar`, `playback_section`, or most screen-level widgets, the provider tree typically needs:
- `SettingsProvider`
- `ThemeProvider`
- `AudioProvider`
- `DeviceService`
- `ShowListProvider` (for anything with tab/random state)

### 8. Mock Regeneration
If Mockito mock classes are missing methods after an interface change:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Run from the package root where the mocks are defined.
