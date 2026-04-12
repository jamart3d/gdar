---
description: Standardized Mockito regeneration and mock parity repair.
---
# Mock Regeneration Workflow (Monorepo)

**TRIGGERS:** mock_regen, regen_mocks, mock regen

**When to use:** When tests fail with `ProviderNotFoundException`,
`MissingStubError`, or fake/mock drift after modifying core providers or
services.

> [!NOTE]
> **MONOREPO**: Core providers live in `packages/shakedown_core/`. Tests may be in any app target's `test/` dir or `packages/shakedown_core/test/`. Run `build_runner` from the package/app that owns the test.

1. **Analyze Failure:** Read the `flutter test` output to identify the exact
   failing test file and the missing stub, provider, or override.
2. **Locate Test Setup:** Open the corresponding `_test.dart` file and locate
   the mock or fake initialization block (usually `setUp()`).
3. **Repair Generated Mocks:**
   - If using `build_runner`, ensure the `@GenerateMocks` annotation includes
     the modified class.
   - Run `dart run build_runner build --delete-conflicting-outputs` from the
     package/app that owns the test.
4. **Repair Fake/Manual Provider Parity:**
   - When `SettingsProvider`, `DefaultSettings`, or a similar provider gains a
     new property, setter, or toggle, check fake providers across:
     - `apps/gdar_mobile/test/`
     - `apps/gdar_tv/test/`
     - `packages/shakedown_core/test/`
   - Ensure every required getter/setter used by tests has a matching stubbed
     `@override` or equivalent fake implementation.
5. **Inject Required Stubs:** Add the needed `when().thenReturn()` or
   `when().thenAnswer()` logic based on the new service signature.
   - Reference: `docs/TEST_MOCKING_TEMPLATES.md` for standardized
     MultiProvider setups when helpful.
6. **Verify:** Run the specific failing test file:
   `flutter test apps/gdar_mobile/test/path/to/file_test.dart`.
7. **Report:** Confirm the repaired test path and pass/fail outcome.

