# Antigravity Agentic Glossary

This document defines the specialized terminology and cognitive patterns used by Antigravity agents (Arlo, Jules, etc.) within the **gdar** ecosystem. Understanding these terms helps ensure alignment and prevents metadata loss.

---

## 🧠 Cognitive Patterns

### 1. Cognitive Compression
**Definition**: The tendency of an AI model to summarize or paraphrase specific technical data (CLI commands, Bash scripts, deep-link maps) into high-level summaries.
**Risk**: Significant "Metadata Loss" where the *intent* remains but the *execution strings* are deleted. 
**Mitigation**: Mandatory Atomic Moves and Anchor Content verification.

### 2. Architectural Drift
**Definition**: The gradual divergence of a project's implementation or documentation from the established platform standards (Antigravity v1.20.3).
**Detection**: Automated via the `/audit` workflow.

### 3. Dependency Ripple
**Definition**: A cascading series of breakages caused by modifying a core "Source" (e.g., `SettingsProvider` or `AudioRepository`).
**Handling**: Requires "Ripple Control" diagnostics to identify downstream victims.

### 4. Negative Constraint Integrity
**Definition**: The absolute requirement to purge terminology, features, or design patterns that have been explicitly rejected by the user from all active artifacts (`task.md`, `implementation_plan.md`).

---

## 🏗 System Architecture

### 1. The Brain
**Definition**: The local filesystem directory where the agent stores its long-term session context, implementation plans, and walkthroughs.
**Path**: `~/.gemini/antigravity/brain/`

### 2. Handoff Point
**Definition**: A root-level document (strictly `AGENTS.md`) designed to provide a "Cold Start" context for verification agents like **Jules**. It defines "Who" the agent is and "What" the project goals are.

### 3. Anchor Content
**Definition**: Specific, non-summarizable text blocks—typically complex CLI commands or architectural diagrams—that serve as the "Anchor" for a document's technical utility.

---

## 🔊 gdar-Specific Domain Terms

### 1. Vapor Transitions
**Definition**: A specialized gdar audio state where the engine prepares the next track's buffer *inside* the current playback loop to ensure zero-latency gapless-ness.

### 2. Fruit Style (Liquid Glass)
**Definition**: An optional Web-only theme layer characterized by high transparency, BackdropFilter effects, and Inter typography.

### 3. OLED/True Black
**Definition**: A display mode that removes all background colors (`#000000`) while preserving hierarchy through subtle glow and shadow effects.

---
*Created: March 2026*
