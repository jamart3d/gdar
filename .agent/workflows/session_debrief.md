---
description: Analyze the day's work and suggest new agent tools/docs.
---
# Session Debrief Workflow

**When to use:** At the end of a coding session to extract reusable knowledge and improve the agent's environment.

1.  **Analyze Activity:** Review the recent git commits, completed tasks in `todo.md`, and the conversation history of the current session.
2.  **Identify Patterns:** Look for:
    *   Repeated commands or debugging steps.
    *   Newly discovered architectural constraints or UI gotchas.
    *   Successful multi-step processes.
    *   Missing documentation that caused confusion.
3.  **Propose Enhancements:** Generate a concise list of suggestions categorized into:
    *   **Rules (`.agent/rules`):** E.g., "Add rule to always check X before Y."
    *   **Skills (`.agent/skills`):** E.g., "Create skill for testing WebSockets."
    *   **Workflows (`.agent/workflows`):** E.g., "Create a `/deploy_staging` workflow."
    *   **Specs/Docs:** E.g., "Document the new caching layer."
4.  **Execute:** Ask the user which suggestions they approve, and immediately generate the selected `.md` files.
