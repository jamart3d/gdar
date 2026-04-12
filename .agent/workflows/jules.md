---
description: Dispatch a bounded job to Jules with a clean task brief and repo context.
---
# Jules Dispatch Workflow

**TRIGGERS:** jules, dispatch, handoff, delegate, verify-all

Use this workflow when the goal is to send Jules a concrete job, audit, or
verification task rather than execute the work locally.

## Goal

Create a clean Jules job that includes:
- a short title
- the exact task to perform
- the intended repo scope
- required verification
- the expected deliverable back

## Inputs

When the user already provided enough detail, use it directly.

If key details are missing, gather only the minimum needed:
- job title
- objective
- scope or target paths
- expected output

Do not turn this into a broad planning session. The purpose is dispatch.

## Workflow

1. **Capture local context**
   - Check current branch and worktree status.
   - Identify the most relevant touched files or target paths for the job.
   - Summarize the current task state in 2-5 short bullets.

2. **Build the Jules brief**
   Create a concise task brief with these sections:
   - `Title`
   - `Objective`
   - `Scope`
   - `Constraints`
   - `Verification`
   - `Expected Output`

   Preferred defaults:
   - `Scope`: only the files or directories relevant to the request
   - `Constraints`: preserve platform rules, do not revert unrelated user work,
     keep package-import discipline
   - `Verification`: targeted tests first, then broader checks only if needed
   - `Expected Output`: findings, patch summary, changed files, and follow-up
     risks or blockers

3. **Dispatch**
   Run Jules from the repo root with the composed title and brief.

4. **Return handoff details**
   Report back:
   - the Jules job title
   - the exact scope sent
   - the session URL or ID
   - any important caveats passed through in the brief

## Brief Template

Use this shape when composing the Jules job:

```text
Title: <short title>

Objective:
<what Jules should do>

Scope:
- <path or subsystem>
- <path or subsystem>

Constraints:
- Preserve unrelated user changes
- Follow GDAR platform/UI rules
- Use package imports across library boundaries

Verification:
- <targeted test or audit>
- <broader verify step if needed>

Expected Output:
- <report, fixes, findings, or status>
```

## Guardrails

- Prefer a bounded job over a vague "look around" request.
- Do not require a clean worktree unless the job truly depends on it.
- Include only relevant paths; avoid dumping the entire repo when a narrower
  scope will do.
- If the user asks Jules to review or audit, tell Jules whether the output
  should be findings-only, fixes, or both.
- If Jules tooling is unavailable, report that clearly and stop.
