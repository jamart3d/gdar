---
description: Ensure all experimental/premium settings are disabled before a release.
---

# Workflow: Verify Settings Defaults (Monorepo)

**TRIGGERS:** verify_settings_defaults, verify_metadata

This workflow ensures the application's initial state remains clean and un-opinionated for new installations.

> [!NOTE]
> **MONOREPO**: Settings provider lives in `packages/shakedown_core/`.

1. **Verify `DefaultSettings`**:
   Compare `packages/shakedown_core/lib/providers/settings_provider.dart` (or the corresponding defaults file) against the requirement that experimental features must be `false` by default.

2. **Check list**:
   * `oilTvPremiumHighlight` -> `false`
   * `oilLiquidGlass` -> `false`
   * `fruitDenseList` -> `false`
   * `oilEnableVisualizer` -> `false` (on non-TV platforms)

3. **Validate Initialization**:
   Ensure `shared_preferences` or `Hive` initialization doesn't force a "last seen" state that overrides these for fresh installs.

4. **Remediation**:
   If any setting is incorrectly set to `true`, update the file to `false` and log the correction.
