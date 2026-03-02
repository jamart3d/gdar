---
description: Automatically identify and fix MissingStubError or ProviderNotFoundException in Flutter tests.
---
# Test Fixer Workflow

**TRIGGERS:** fix test, stub, mock, provider, exception

This workflow targets common boilerplate-related test failures efficiently.

> [!IMPORTANT]
> **AUTONOMY & PLANNING MODE**: When this workflow is triggered, switch to **Planning Mode**. Proceed autonomously end-to-end (running tests, reading logs, and applying surgical fixes) to ensure tests pass without needing constant validation for every change.

## 1. Run Tests & Capture Failures
// turbo
1. Execute the failing test file: `flutter test <path_to_test_file>`.
2. Capture the output to identify:
   - `MissingStubError: ... on mockAudioPlayer.currentIndex` (or similar).
   - `ProviderNotFoundException: ... <ThemeProvider> ... not found`.

## 2. Identify the Fix Pattern
- If **MissingStubError**:
  1. Find the `setUp` or test body where the mock is initialized.
  2. Refer to the `test_mocking_templates` skill for the appropriate `when(...)` block.
  3. Inject the `when(mockObject.propertyName).thenReturn(defaultValue);` code.
- If **ProviderNotFoundException**:
  1. Find the `createTestableWidget` helper or `MultiProvider` in the test file.
  2. Refer to the `test_mocking_templates` skill for the standardized `MultiProvider` setup.
  3. Add the missing `ChangeNotifierProvider.value(value: mockProvider)` or equivalent.

## 3. Apply Fix with Surgical Edits
// turbo
1. Use `replace_file_content` to make the specific, minimal change needed.
2. DO NOT rewrite the entire test file.

## 4. Verification
// turbo
1. Re-run the tests: `flutter test <path_to_test_file>`.
2. Confirm the exact failure is resolved.
