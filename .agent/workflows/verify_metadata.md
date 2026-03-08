---
description: Ensure all experimental/premium settings are disabled before a release.
---

# Verify Metadata Workflow

**When to use:** Before running `shipit` to ensure version consistency and clean release states.

1.  **Check Version Parity**:
    - Compare `version` in `pubspec.yaml` with the latest entry in `CHANGELOG.md`.
    - Compare with the latest entry in `docs/PLAY_STORE_RELEASE.txt`.

2.  **Audit Experimental Gates**:
    - Run `/verify_settings_defaults` to ensure "Liquid Glass" and other premium features are off by default.

3.  **Validate Links**:
    - Ensure `sourceUrl` and `Internet Archive` links are present in the latest release notes if applicable.
