# AI Agents Overview.md — Project Instructions for Agents
## Project Overview

This repository is an **AI Skill Library** — a collection of reusable skills, prompts, and tools designed to be invoked by AI agents (Claude Code, GitHub Copilot, etc.) from within VS Code chat.

## Repository Structure

| Directory      | Purpose                                                       |
|----------------|---------------------------------------------------------------|
| `skills/`      | Individual skill definitions (each skill in its own `skills/<name>/skill.md` folder) |
| `prompts/`     | Reusable prompt templates and system prompts                  |
| `tools/`       | Helper scripts and tool definitions that skills can invoke    |
| `templates/`   | Scaffolding templates for creating new skills and prompts     |
| `config/`      | Configuration files for skill behavior and defaults           |

## Conventions

### Skill Files
- Each skill lives in its own folder under `skills/<skill_name>/skill.md`.
- Folder names use `snake_case` (e.g., `skills/code_review/skill.md`).
- Skills follow the template in `templates/skill_template.md`.
- Every skill must include: **Name**, **Description**, **Inputs**, **Steps**, and **Output** sections.
- Additional skill assets (scripts, configs, examples) can be placed alongside `skill.md` in the same folder.

### Prompt Files
- System prompts live in `prompts/system/`.
- Task-specific prompt templates live in `prompts/templates/`.
- Prompts use `{{placeholder}}` syntax for variable substitution.

### Tools / Scripts
- Executable scripts live in `tools/scripts/`.
- Each script has a companion README or header comment describing its usage.

## Skill Resolution & Precedence

This repository (`ai_agent`) serves as your **general-purpose personal skill library** — the baseline set of skills, prompts, and tools. However, when multiple workspace folders are open, skills from other sources may **override** the ones defined here.

### Precedence Order (highest → lowest priority)

| Priority | Source | Description |
|----------|--------|-------------|
| **1 — Highest** | **Project-specific skills** | Skills defined in the current project's repository (e.g., a `skills/` or `.ai/skills/` folder within the project being worked on). These enforce project standards and always take precedent. |
| **2** | **Other open workspace libraries** | Skills from other repositories or libraries open in the same VS Code workspace (i.e., any non-`ai_agent` folder that contains skills). These act as team or domain overrides. |
| **3 — Lowest** | **This library (`ai_agent`)** | The general/default skill library. Used as a fallback when no higher-priority source provides the same skill. |

### How Precedence Works

- **Exact match override**: If a skill with the **same name** (folder name under `skills/`) exists in a higher-priority source, use that version entirely. Do **not** merge or blend skill definitions from different sources.
- **Conflict resolution**: If two non-`ai_agent` sources both define the same skill, prefer the **project-specific** version. If neither is project-specific, prefer the one whose repository is the **active working context** (the folder the user is currently working in).
- **Fallback**: If no higher-priority source defines a skill, fall back to this library.
- **Additive skills**: Skills that exist **only** in this library (with no counterpart elsewhere) are always available regardless of precedence.

### Why This Matters

- **Project standards come first** — a project may enforce specific review checklists, testing frameworks, or commit conventions that differ from the general defaults here.
- **Team/domain libraries override personal defaults** — when a shared team library is open, its skills reflect agreed-upon practices and should take priority.
- **This library is the safety net** — it ensures a skill is always available even when a project or team library doesn't define one.

### Detecting Skill Sources

When resolving a skill, scan all open workspace folders for skill definitions:

1. Look for `skills/<skill_name>/skill.md` in each workspace folder.
2. Check for `.ai/skills/<skill_name>/skill.md` as an alternate convention.
3. Check for a `skill_library.md` or equivalent index in each folder.
4. Apply the precedence order above to select the winning definition.

If a higher-priority skill is found, log or note which source is being used so the user has visibility.

---

## How to Use Skills

When a user asks you to perform a task, first apply the **Skill Resolution & Precedence** rules above to find the correct skill definition. Then:

1. Read the skill file from the winning source's `skills/<skill_name>/skill.md`.
2. Follow the **Steps** section exactly.
3. Use any referenced prompts from `prompts/` (prefer the skill source's prompts if available).
4. Invoke any referenced tools from `tools/` (prefer the skill source's tools if available).
5. Return output in the format specified by the skill's **Output** section.

If no matching skill exists in any open workspace folder, offer to create one using `templates/skill_template.md`.

## Code Style & Standards
- Markdown files: ATX headings (`#`), fenced code blocks with language tags.
- Scripts: Include error handling, comments, and a usage header.
- JSON config: 2-space indentation, no trailing commas.

## Important Notes
- Always read `skill_library.md` first when looking for available skills.
- Skills are composable — one skill can reference another.
- When creating new skills, register them in `skill_library.md`.
