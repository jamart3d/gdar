---
name: zero_friction_execution
description: Core mechanics for executing asynchronous long-running workflows (checkup, shipit, deploy) without timing out or violating the "No Black Box" rule.
---

# Zero-Friction Execution Skill

When you are triggered to execute a Zero-Friction workflow (e.g., `/shipit`, `/deploy`, `/checkup`, `/hammer`), you are expected to operate completely autonomously. However, you MUST follow these mechanical constraints for interacting with the local terminal tools to prevent LLM timeouts, prevent UI lockups, and ensure hardware constraints are met.

## 1. Asynchronous Execution (Anti-Timeout Protocol)
Commands like `flutter build appbundle`, `melos run test`, and `firebase deploy` can take several minutes to complete. You must NEVER attempt to wait for them synchronously.

- Use the current terminal command tool for each command as its own step.
- Start long-running commands promptly and avoid bundling unrelated work into a single shell string.
- If a command does not return quickly, switch to explicit status checking instead of waiting indefinitely.

## 2. The Polling Loop (No Black Boxes)
Once a long-running command is in flight, you must respect the **Sequential Execution** rule. You may not start the next target build or verification phase until the current one finishes.

- Check for real completion signals: process exit, returned shell prompt, or terminal final status lines.
- Do not remain silent. Provide the user with quick update messages while the command is running.
- If the command state becomes uncertain after an interrupt, treat it as unknown and re-check process state plus terminal output before claiming it is still running.

## 3. Fail-Fast Exit 
If the command exits with a non-zero result:
1. Instantly **ABORT** the current workflow sequence. (Do not move to the Web build if the Android build failed).
2. Report the error using the final lines of the stderr/stdout.
3. Await human instruction. Do not automatically rewrite their code unless explicitly instructed via the `/checkup` automatic fixes (`melos run fix`).
