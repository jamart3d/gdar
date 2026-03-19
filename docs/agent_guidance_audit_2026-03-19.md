# Agent Guidance Audit

Date: 2026-03-19
Project: GDAR
Scope: `AGENTS.md` and `.agent/`

## Overall Score

**6.2/10**

The agent guidance is useful and clearly written in parts, but it is carrying
too much stale, conflicting, or overly rigid instruction to be a fully
trustworthy system.

The strongest parts are the repo-specific platform contracts and the
high-signal rules around Fruit boundaries and monorepo behavior. The weakest
parts are the files that try to over-specify agent behavior using outdated or
fictional tool assumptions.

## What Is Working Well

### `AGENTS.md`

Strengths:

- Good project framing
- Good monorepo shape and package/app boundary guidance
- Clear platform contract across Android, TV, and Fruit web
- Clear coding expectations for Flutter/Dart work
- Useful large-data warning around the optimized JSON file

### High-Value `.agent` Files

These feel specific, useful, and worth keeping in some form:

- `.agent/rules/fruit_theme_boundaries.md`
- `.agent/rules/monorepo_builds.md`
- `.agent/rules/tv_rules.md`
- `.agent/workflows/verify.md`

Why they work:

- They encode real repo constraints
- They are small enough to follow
- They improve consistency without inventing fake mechanics

## Main Problems

### 1. Tooling Fiction / Drift

Some instructions describe an execution environment that is not actually the
current one.

Examples:

- `AGENTS.md` requires `SafeToAutoRun: true`
- `AGENTS.md` requires first-turn recursive `.agent/` indexing
- `AGENTS.md` requires silent `--help` verification for primary tools
- `.agent/rules/efficiency_guardrails.md` requires `view_file_outline`
- `.agent/rules/platform_shell.md` says Windows commands should always use
  `cmd /c`

Why this is a problem:

- The agent starts trusting repo docs over the real tool contract
- It creates unnecessary friction
- It can actively push the agent into wrong execution behavior

### 2. Over-Constraint

Some rules are so strict that they fight productive coding behavior.

Best example:

- `.agent/rules/efficiency_guardrails.md`

Problem areas:

- "Always preview and wait for confirmation before executing"
- "Only read files the user explicitly mentions"
- "Always call `view_file_outline` before reading a file"

Why this is overkill:

- It prevents normal codebase discovery
- It blocks efficient bug fixing
- It is partially based on tools that do not exist in the current environment

### 3. Internal Contradictions

Some guidance disagrees with itself.

Best example:

- `.agent/rules/auto_approve.md`

Conflict:

- `dart format .` is listed under auto-approved/read-only commands
- Later, `dart format` is listed under "NEVER Auto-Approve" because it mutates
  files

Why this matters:

- Contradictions create inconsistent agent behavior
- The more files you have, the more dangerous this gets

### 4. Risky Workflow Defaults

Some workflows do too much for their trigger phrase.

Best example:

- `.agent/workflows/save.md`

Current behavior:

- `git add .`
- `git commit`
- `git push`

Why this is risky:

- "save" is too casual a trigger for staging and pushing an entire monorepo
- It assumes a clean understanding of the worktree
- It is dangerous in a repo with shared packages and many moving parts

## File-Level Assessment

### Keep Mostly As-Is

- `AGENTS.md`
  Keep the repo/platform guidance, but trim the agent-protocol section.
- `.agent/rules/fruit_theme_boundaries.md`
- `.agent/rules/monorepo_builds.md`
- `.agent/workflows/verify.md`

### Keep, But Rewrite

- `.agent/rules/auto_approve.md`
  Keep the intent, remove contradictions, align with current tooling.
- `.agent/rules/tv_rules.md`
  Keep the platform discipline, soften absolute statements where exceptions are
  normal.
- `.agent/rules/efficiency_guardrails.md`
  Rewrite heavily or replace with a much smaller practical version.
- `.agent/workflows/save.md`
  Keep as a concept, but make it safer and less automatic.

### Delete Or Collapse

- `.agent/rules/platform_shell.md`
  The current shell/runtime should be owned by the actual environment, not this
  file.
- Any rule that only exists to enforce fake command metadata or nonexistent
  tools
- Any workflow that duplicates another workflow without a clear behavioral
  distinction

## Overkill Assessment

Yes, some of this is overkill.

What feels overbuilt:

- 22 rule files plus 24 workflows is a lot for a repo of this size unless the
  curation is extremely disciplined
- multiple files are trying to control agent execution mechanics instead of
  encoding repo truth
- several rules read like defensive prompts against older agent behavior rather
  than current, practical repo guidance

What does *not* feel overkill:

- platform-specific rules when they encode real product differences
- monorepo-specific build guidance
- focused verification workflows
- working specs for Fruit/TV/web audio where the repo truly has unusual product
  behavior

## Recommended Next Passes

### Pass 1: Accuracy Cleanup

Goal:

- Remove or rewrite anything that no longer matches the real tool/runtime
  environment

Priority files:

- `AGENTS.md`
- `.agent/rules/efficiency_guardrails.md`
- `.agent/rules/platform_shell.md`
- `.agent/rules/auto_approve.md`

Deliverable:

- No references to nonexistent tools or fake execution metadata
- No shell guidance that conflicts with the actual runtime

### Pass 2: Workflow Safety

Goal:

- Make high-impact workflows safer and less surprising

Priority files:

- `.agent/workflows/save.md`
- `.agent/workflows/shipit.md`
- `.agent/workflows/checkup.md`

Deliverable:

- "save" does not implicitly mean "stage everything and push"
- release/deploy triggers remain explicit
- workflow boundaries are easy to understand

### Pass 3: Rule Consolidation

Goal:

- Reduce the number of low-value or overlapping rule files

Approach:

- Merge tiny overlapping rules into a few stronger files
- separate "repo truths" from "agent behavior preferences"

Suggested buckets:

- platform rules
- build/test/verification rules
- runtime/audio rules
- docs/spec hygiene rules

Deliverable:

- fewer, clearer rule files
- lower maintenance cost
- less contradiction risk

### Pass 4: Tiering

Goal:

- Distinguish between mandatory rules and optional guidance

Suggested labels:

- `mandatory`
- `default`
- `advisory`
- `stale`

Deliverable:

- easier pruning
- easier onboarding for future agent sessions

## Suggested Target State

If cleaned up well, this guidance system could realistically reach:

**8/10**

That would require:

- fewer contradictory rules
- better alignment with the real execution environment
- safer workflow defaults
- a smaller set of higher-signal files

## Bottom Line

The guidance system has good bones, but it is trying to be more controlling
than accurate. The next improvement should not be adding more rules. It should
be pruning, rewriting, and tightening the existing ones until the guidance only
states things that are both true and useful.
