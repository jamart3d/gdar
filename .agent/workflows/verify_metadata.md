---
description: Ensure all experimental/premium settings are disabled before a release.
---

# Verify Metadata Workflow (Monorepo)

**When to use:** Before running `shipit` to ensure version consistency and clean release states.

> [!NOTE]
> **MONOREPO**: The workspace root `pubspec.yaml` has NO `version:` field. Version lives in each app target's `pubspec.yaml`.

1.  **Check Version Parity**:
    - Compare `version` across all app targets:
      - `apps/gdar_mobile/pubspec.yaml`
      - `apps/gdar_tv/pubspec.yaml`
      - `apps/gdar_web/pubspec.yaml`
    - All three MUST have the same `version:` value.
    - Compare with the latest entry in `CHANGELOG.md`.

2.  **Audit Experimental Gates**:
    - Run `/verify_settings_defaults` to ensure "Liquid Glass" and other premium features are off by default.

3.  **Validate Links**:
    - Ensure `sourceUrl` and `Internet Archive` links are present in the latest release notes if applicable.
