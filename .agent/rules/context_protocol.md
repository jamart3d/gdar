# Context Diagnostic Integrity Rule (CDI)

To maintain absolute transparency in agent-driven sessions, all Antigravity agents working in the GDAR monorepo MUST adhere to the following reporting cadence. This ensures the human developer is always aware of the "Working Memory" load and potential for context truncation.

## 1. Context Pulse (The Metric)
The **Context Pulse** is a calculated estimate of the current token usage relative to the primary attention window (standardized to 1M tokens).

- **Format**: `Context Pulse: ~XX% Used (Status) | T: [Turn Count] | SHA: [Git Reference]`
- **Status Indicators**: `Stable` (< 40%), `Dense` (40-70%), `Caution` (> 70% / Impending Truncation).

## 2. Reporting Intervals (Mandatory)
The agent MUST output a Context Pulse block at the following lifecycle events:

### **Fixed Intervals**
- **Turn Cadence**: Every 3 turns of active conversation.
- **Workflow Exit**: Immediately upon the successful (or failed) completion of any slash command (e.g., `/validate`, `/publish`, `/audit`).

### **High-Load Triggers**
- **Bulk Discovery**: After using `ls -R` or `find` to map the workspace at the start of a session.
- **Deep Audit**: After reading more than 500 lines of source code or a full speculative design directory.

## 3. Communication Style
- The Pulse should be presented as a GitHub alert (Note or Tip) at the end of the response to minimize noise while maintaining visibility.
- If the Context Pulse exceeds 75%, the agent MUST proactively suggest a context-clearing strategy (e.g., "Would you like me to summarize our progress so far to keep the reasoning window sharp?").
