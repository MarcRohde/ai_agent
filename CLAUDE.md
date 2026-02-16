# CLAUDE.md — Project Instructions for Claude Code

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

## How to Use Skills

When a user asks you to perform a task, check `skill_library.md` for a matching skill. If one exists:

1. Read the skill file from `skills/<skill_name>/skill.md`.
2. Follow the **Steps** section exactly.
3. Use any referenced prompts from `prompts/`.
4. Invoke any referenced tools from `tools/`.
5. Return output in the format specified by the skill's **Output** section.

If no matching skill exists, offer to create one using `templates/skill_template.md`.

## Code Style & Standards
- Markdown files: ATX headings (`#`), fenced code blocks with language tags.
- Scripts: Include error handling, comments, and a usage header.
- JSON config: 2-space indentation, no trailing commas.

## Important Notes
- Always read `skill_library.md` first when looking for available skills.
- Skills are composable — one skill can reference another.
- When creating new skills, register them in `skill_library.md`.
