---
description: Ensure SettingsProvider keys match FakeSettingsProvider / MockSettingsProvider tests.
---

# Check Mock Parity Workflow

**When to use:** Use this immediately whenever a new property, toggle, or configuration key is added to `SettingsProvider` or `DefaultSettings` to prevent cascading failures in the widget and unit testing suite.

1. **Search Context**: Use the `view_file` or `grep_search` tool to isolate the newly added `oil*` setting in `lib/providers/settings_provider.dart`. You should note its type, name, and related setter function.
2. **Review Target Mocks**: Check `test/tv_regression_test.dart` and `test/screens/playback_screen_tv_test.dart` (or any other tests holding `FakeSettingsProvider` or `MockSettingsProvider`).
3. **Parity Check**: Ensure that for every property/getter (e.g., `bool get oilShowNewFeature`) and setter function (e.g., `Future<void> toggleOilShowNewFeature() async {}`) in the main settings provider, there is a stubbed `@override` version inside the fake blocks.
4. **Resolution**: Modify the testing mock definitions to adhere perfectly to the provider's signature using `replace_file_content`.

> [!TIP]
> Never skip this parity workflow after a settings update. `ProviderNotFoundException` or "Doesn't Override" type errors in Jules audits are almost unconditionally traced back to missing `FakeSettingsProvider` overrides.
