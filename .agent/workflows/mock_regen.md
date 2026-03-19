---
description: Standardized Mockito test stub regeneration
---
# Mock Regeneration Workflow (Monorepo)

**When to use:** When tests fail with `ProviderNotFoundException` or `MissingStubError` after modifying core providers or services.

> [!NOTE]
> **MONOREPO**: Core providers live in `packages/shakedown_core/`. Tests may be in any app target's `test/` dir or `packages/shakedown_core/test/`. Run `build_runner` from the package/app that owns the test.

1.  **Analyze Failure:** Read the `flutter test` output to identify the exact failing test file and the missing stub or provider.
2.  **Locate Test Setup:** Open the corresponding `_test.dart` file and locate the mock initialization block (usually `setUp()`).
3.  **Update Mocks:** 
    *   If using `build_runner`, ensure the `@GenerateMocks` annotation includes the modified class.
    *   Run `dart run build_runner build --delete-conflicting-outputs` from the package/app that owns the test.
4.  **Inject Stubs:** Inject the required `when().thenReturn()` or `when().thenAnswer()` logic based on the new service signature.
    *   *Reference:* Consult `docs/TEST_MOCKING_TEMPLATES.md` (if it exists) for standardized MultiProvider setups.
5.  **Verify:** Run the specific failing test file: `flutter test apps/gdar_mobile/test/path/to/file_test.dart`.
6.  **Report:** Confirm pass rate.

