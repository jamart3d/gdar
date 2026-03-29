# Testing & Verification Standards

### 1. Provider Fakes & Stubbing
The codebase standard favors **fake classes** that implement the provider interface over Mockito mocks, utilizing `noSuchMethod` to handle un-stubbed calls without `MissingStubError`.
```dart
class _FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  bool get performanceMode => false;
  // ... only override what the test actually needs ...

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
```

### 2. Critical: Extension Methods Break Fakes
Dart extension methods dispatch statically against the compile-time type. If a provider (e.g., `SettingsProvider`) uses extension methods to split getters, they will execute on the fake instead of via dynamic dispatch and try to access private fields the fake lacks.
**Do NOT use Dart extension methods to split providers.** Use separate classes or mixins.

### 3. Widget Test Surface Sizes & Overflows
To prevent `computeSize` layout failures and `RenderFlex` overflows when testing complex visual layers (e.g., `ShowListCard` gradients/shaders), always set a larger physical size in `testWidgets` and ensure it resets via `addTearDown`.
```dart
testWidgets('visual state verification', (tester) async {
  tester.view.physicalSize = const Size(1000, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  // ... build and pump ...
});
```

### 4. TV & Web Compile-Time Constants
- `kIsWeb` is a compile-time constant, always `false` in unit tests. Web-specific `SettingsProvider` branches cannot be exercised by unit tests.
- To exercise TV defaults, pass `isTv: true` explicitly to the constructor: `SettingsProvider(prefs, isTv: true);`
- `ThemeStyle` has exactly two values: `ThemeStyle.android` and `ThemeStyle.fruit`. `ThemeStyle.classic` does not exist.

### 5. Required Widget Test Providers
When testing full screens or complex widgets (like `FruitTabBar`), the provider tree generally requires:
- `SettingsProvider`, `ThemeProvider`, `AudioProvider`, `DeviceService`, `ShowListProvider`

### 6. Mockito Code Generation
If Mockito mock classes are missing methods after interface changes, run from the respective package root:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 7. Known Local Test Failures
`verify_data_integrity_test.dart` always fails in local development because it requires the 8MB `output.optimized_src.json` asset, which is intentionally excluded from the test environment.
