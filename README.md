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
│   ├── code_review/
│   │   └── skill.md
│   ├── documentation/
│   │   └── skill.md
│   ├── explain_code/
│   │   └── skill.md
│   ├── generate_tests/
│   │   └── skill.md
│   ├── git_operations/
│   │   └── skill.md
│   └── refactor/
│       └── skill.md
├── prompts/               # Reusable prompt templates
├── tools/                 # Helper scripts and utilities
├── templates/             # Templates for creating new skills/prompts
└── config/                # Configuration and defaults
```

## Creating a New Skill

1. Create a new folder in `skills/` named after your skill (e.g., `skills/your_skill_name/`).
2. Copy `templates/skill_template.md` into the folder as `skill.md`.
3. Fill in all sections (Name, Description, Inputs, Steps, Output).
4. Register the skill in `skill_library.md`.
5. Optionally add supporting prompts in `prompts/templates/`.
6. Place any additional skill-specific assets (scripts, configs, examples) alongside `skill.md` in the same folder.

## Skill Precedence

This library is your **general-purpose personal skill library** — the baseline. When the workspace contains multiple folders, skill precedence is applied:

| Priority | Source | Overrides this library? |
|----------|--------|-------------------------|
| **Highest** | Project-specific skills (in the active project repo) | Yes — always |
| **Middle** | Other open workspace libraries | Yes — same-name skills override |
| **Lowest** | This library (`ai_agent`) | Baseline / fallback |

This ensures project standards and team conventions are always respected. See [AI Agents Overview.md](AI%20Agents%20Overview.md) for detailed resolution rules.

## Skill Categories

| Category         | Description                              | Examples                        |
|------------------|------------------------------------------|---------------------------------|
| **Code Quality** | Review, lint, refactor                   | `code_review/`, `refactor/`     |
| **Testing**      | Generate and run tests                   | `generate_tests/`               |
| **Documentation**| Generate docs, READMEs, comments         | `documentation/`                |
| **Git**          | Branching, commits, PR workflows         | `git_operations/`               |
| **Explanation**  | Explain code, architecture, patterns     | `explain_code/`                 |

## Contributing

1. Follow the skill template format (`skills/<skill_name>/skill.md`).
2. Keep skills focused — one task per skill.
3. Test your skill by invoking it from VS Code chat.
4. Update `skill_library.md` with the new entry.

## License

Internal use — Andis Company.
