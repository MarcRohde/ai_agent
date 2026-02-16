# AI Agent Skill Library

A structured collection of AI skills, prompts, and tools designed to be invoked by AI coding agents (Claude Code, GitHub Copilot, etc.) from within VS Code.

## What Is This?

This repository acts as a **skill library** — a knowledge base that AI agents can read and execute to perform common development tasks consistently and reliably. Instead of relying on ad-hoc prompting, skills encode best practices into repeatable, versioned instructions.

## Quick Start

1. Open this repository in VS Code.
2. Start a chat session with Claude Code (or another AI agent).
3. Ask it to perform a task — it will consult `CLAUDE.md` and `skill_library.md` to find the right skill.
4. The agent reads the skill definition and executes the steps.

## Repository Structure

```
ai_agent/
├── CLAUDE.md              # Agent project instructions (read first)
├── README.md              # This file
├── skill_library.md       # Master index of all skills
├── skills/                # Individual skill definitions
├── prompts/               # Reusable prompt templates
├── tools/                 # Helper scripts and utilities
├── templates/             # Templates for creating new skills/prompts
└── config/                # Configuration and defaults
```

## Creating a New Skill

1. Copy `templates/skill_template.md` to `skills/your_skill_name.md`.
2. Fill in all sections (Name, Description, Inputs, Steps, Output).
3. Register the skill in `skill_library.md`.
4. Optionally add supporting prompts in `prompts/templates/`.

## Skill Categories

| Category         | Description                              | Examples                        |
|------------------|------------------------------------------|---------------------------------|
| **Code Quality** | Review, lint, refactor                   | `code_review`, `refactor`       |
| **Testing**      | Generate and run tests                   | `generate_tests`                |
| **Documentation**| Generate docs, READMEs, comments         | `documentation`                 |
| **Git**          | Branching, commits, PR workflows         | `git_operations`                |
| **Explanation**  | Explain code, architecture, patterns     | `explain_code`                  |

## Contributing

1. Follow the skill template format.
2. Keep skills focused — one task per skill.
3. Test your skill by invoking it from VS Code chat.
4. Update `skill_library.md` with the new entry.

## License

Internal use — Andis Company.
