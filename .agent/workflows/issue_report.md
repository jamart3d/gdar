---
description: Investigate a specific codebase issue and generate a standardized report.
---
# Issue Report Workflow

**TRIGGERS:** /issue_report, investigate, bug report, dig into

> [!IMPORTANT]
> **AUTONOMY OVERRIDE & PLANNING MODE**: When this workflow is triggered, switch to **Planning Mode** (`/plan` or toggling the UI) to guarantee a deep architectural investigation. Proceed autonomously end-to-end (reading files, testing, and writing the final report markdown file) without stopping for intermediate permission. Only pause and ask the user if you encounter a blocking issue, need clarification on the bug, or have fully completed the report.

## Investigation & Reporting Steps
1. **Get App Version**: Read `pubspec.yaml` to explicitly get the current app version.
2. **Current Time**: Get the current local time.
3. **Investigate**: Use codebase search, `view_file`, `mcp_dart-mcp-server_analyze_files`, etc. to investigate the issue provided by the user.
4. **Format Name**: Generate a filename using the current date, time, and app version (e.g., `reports/YYYY-MM-DD_HH-MM_v1.0.3+3_issue_name.md`).
5. **Generate Report**: Create the markdown file in the `reports/` directory using the `write_to_file` tool. create the directory if it doesn't exist.
6. **Content**: The report must include:
    - Issue Summary
    - Files Affected
    - Potential Causes
    - Proposed Solutions / Next Steps
