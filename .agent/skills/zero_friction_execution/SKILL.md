---
name: zero_friction_execution
description: Core mechanics for executing asynchronous long-running workflows (checkup, shipit, deploy) without timing out or violating the "No Black Box" rule.
---

# Zero-Friction Execution Skill

When you are triggered to execute a Zero-Friction workflow (e.g., `/shipit`, `/deploy`, `/checkup`, `/hammer`), you are expected to operate completely autonomously. However, you MUST follow these mechanical constraints for interacting with the local terminal tools to prevent LLM timeouts, prevent UI lockups, and ensure hardware constraints are met.

## 1. Asynchronous Execution (Anti-Timeout Protocol)
Commands like `flutter build appbundle`, `melos run test`, and `firebase deploy` can take several minutes to complete. You must NEVER attempt to wait for them synchronously.

- Use the **`run_command`** tool.
- Set **`SafeToAutoRun: true`** (This enforces the Zero-Friction Mandate).
- **CRITICAL:** Set **`WaitMsBeforeAsync: 5000`**. Do not wait longer than 5 seconds. This forces the system to return a Background Command ID.

## 2. The Polling Loop (No Black Boxes)
Once you have the Background Command ID, you must respect the **Sequential Execution** rule. You may not start the next target build or verification phase until the current one finishes.

- Use the **`command_status`** tool to poll the ID.
- Set `WaitDurationSeconds: 15` (or up to 30) to check progress dynamically.
- Do not remain silent. Provide the user with quick update messages (e.g., *"Android build is at 50%, still compiling..."*) and return control so the human can see the streamed output.
- Repeat the `command_status` poll until the LLM receives `Status: DONE`.

## 3. Fail-Fast Exit 
If `command_status` ever reports an `Exit code` other than `0`:
1. Instantly **ABORT** the current workflow sequence. (Do not move to the Web build if the Android build failed).
2. Report the error using the final lines of the stderr/stdout.
3. Await human instruction. Do not automatically rewrite their code unless explicitly instructed via the `/checkup` automatic fixes (`melos run fix`).
