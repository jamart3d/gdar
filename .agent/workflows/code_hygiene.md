---
description: MCP-native code hygiene audit for dead code and duplication risk.
---
# Code Hygiene Workflow (Monorepo)

**TRIGGERS:** code_hygiene, dead_code, duplicate_code, dedupe

Use this workflow when the goal is source-level bloat control with
**MCP-only execution** (no shell commands).

> [!IMPORTANT]
> This workflow must not invoke terminal commands.
> Use Dart MCP tools only.

## 1. Add Workspace Root (MCP)
- Call `mcp__dart__add_roots` with:
  - `file:///C:/Users/jeff/StudioProjects/gdar`

## 2. Analyzer Pass (MCP)
- Call `mcp__dart__analyze_files` for:
  - `apps/`
  - `packages/`
- Prioritize findings with these analyzer codes:
  - `unused_import`
  - `unused_local_variable`
  - `unused_field`
  - `unused_element`
  - `dead_code`

## 3. Duplicate-Risk Pass (MCP Read/Review)
- Use MCP file reads to inspect high-risk files flagged by analyzer.
- Mark duplicate-risk candidates when:
  - two or more private methods in the same feature area have near-identical
    control flow and branching;
  - similar widget build branches differ only by constants/text;
  - repeated provider/service blocks appear across app targets.

## 4. Architecture Hotspots (MCP)
- In reviewed files, explicitly flag:
  - files over ~800 lines;
  - providers/services with mixed responsibilities;
  - deeply nested widget build sections.

## 5. Save Report
- Ensure `reports/` exists.
- Save results to:
  - `reports/CODE_HYGIENE_REPORT_YYYY-MM-DD.md`
- Include the run date in the report body.

Use this template:
```md
# Code Hygiene Report
Date: YYYY-MM-DD

## Scope
- apps/
- packages/

## Analyzer Findings (Confirmed)
- [severity] path:line - issue

## Duplicate-Risk Candidates
- path:line - summary of repeated logic

## Suggested Cuts
- delete:
- merge:
- extract:

## Notes / False Positives
- note
```

## 6. Reporting Format
Summarize by severity:
1. Confirmed analyzer dead/unused findings
2. Duplicate-risk candidates with file/line references
3. Suggested cuts (delete, merge, extract)
4. False-positive/uncertainty notes

## 7. Guardrails
- Do not auto-delete code from this workflow.
- Treat findings as candidates until verified in context.
- Skip `archive`, `temp`, and `backups` paths unless user explicitly requests
  those folders.
- If exact duplicate detection is required, call out that terminal execution is
  required and wait for user approval before any shell step.
