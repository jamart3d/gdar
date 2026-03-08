---
description: Dynamic audit of project environment against latest live Antigravity specs.
---
# /audit_specs Workflow

This workflow performs a dynamic check of the project's health against the **latest live documentation** from Google Antigravity and Jules.

## Steps

1. **Local Review:**
   - Note the `SPEC_VERSION` reported in recent `env_doctor.py` logs or ask the user to provide a fresh check result.
   - (Note: Agents do not execute `env_doctor.py` directly).

2. **Live Intelligence:**
   - Use `search_web` to look for "Google Antigravity Release Notes" or "Jules AGENTS.md requirements" published after the current `SPEC_VERSION` date (March 2026).
   - Check [jules.google](https://jules.google) or official dev blogs for any "Breaking Changes" in agent file locations.

3. **Drift Reporting:**
   - Generate a **"Spec Drift Report"** as an artifact.
   - **DO NOT** modify files automatically.
   - Highlight any NEW expected files (e.g., `.agent/rules/NEW_SPEC.md`) that the local `env_doctor.py` doesn't know about yet.

// turbo
4. **Manual Check (User Only)**:
If drift is high, the user should run `python tools/env_doctor.py --check` manually.
