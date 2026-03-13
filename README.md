# AI Agent Skill Library

A structured collection of AI skills, prompts, and tools designed to be invoked by AI coding agents (Claude Code, GitHub Copilot, etc.) from within VS Code.

## What Is This?

This repository acts as a **skill library** — a knowledge base that AI agents can read and execute to perform common development tasks consistently and reliably. Instead of relying on ad-hoc prompting, skills encode best practices into repeatable, versioned instructions.

## Quick Start

1. Open this repository in VS Code.
2. Start a chat session with Claude Code (or another AI agent).
3. Ask it to perform a task — it will consult `AGENTS.md` (fallback: `CLAUDE.md`) and `skill_library.md` to find the right skill.
4. The agent reads the skill definition and executes the steps.

## Repository Memory Model

This repository uses a layered model for persistent quality and continuity:

1. **Layer 1 (Global instructions):** short, always-on profile and behavior preferences in agent settings.
2. **Layer 2 (Repository mission):** `AGENTS.md` and `CLAUDE.md` define repo purpose, tree, rules, and note-taking loop.
3. **Layer 3 (Context files):** `context/` files capture standards, examples, and dated lessons.

Lessons learned are intentionally committed in git. When work spans this library and another project repo, capture learnings in both scopes.

## Work IQ MCP Bootstrap

This workspace supports all documented Work IQ MCP servers (`mail`, `user`, `calendar`, `teams`, `word`, `copilot`).

To bootstrap on a new machine:

1. Set `EXO_CLIENT_ID` and `EXO_TENANT_ID`.
	If you also use `start-outlook-auth-server.ps1`, set `EXO_CLIENT_SECRET` too.
2. Ensure Azure CLI is logged in (`az login`).
3. Run one of these:

```powershell
.\tools\scripts\Bootstrap-WorkIQEnvironment.ps1

# or use the general bootstrap entrypoint and chain Work IQ setup
.\tools\scripts\Bootstrap-DevEnvironment.ps1 -Variables @{
	EXO_CLIENT_ID = '<client-app-id>'
	EXO_TENANT_ID = '<tenant-id>'
	EXO_CLIENT_SECRET = '<optional-outlook-auth-server-secret>'
} -BootstrapWorkIQ
```

This flow syncs `.vscode/mcp.json`, acquires tokens for enabled Work IQ scopes, and validates server connectivity. It also seeds `MS_CLIENT_ID` / `MS_TENANT_ID` compatibility variables, plus `MS_CLIENT_SECRET` when provided, so `start-outlook-auth-server.ps1` can reuse the same environment without hardcoded values. If first-run consent is still required, token acquisition can pause on interactive sign-in or consent prompts.

## Repository Structure

```
ai_agent/
├── AGENTS.md              # Primary repository mission file
├── CLAUDE.md              # Agent project instructions (read first)
├── README.md              # This file
├── skill_library.md       # Master index of all skills
├── skills/                # Individual skill definitions
│   ├── andis_bi_sql_change/
│   │   └── skill.md
│   ├── api_resilience/
│   │   └── skill.md
│   ├── code_review/
│   │   └── skill.md
│   ├── dev_environment_bootstrap/
│   │   └── skill.md
│   ├── documentation/
│   │   └── skill.md
│   ├── explain_code/
│   │   └── skill.md
│   ├── generate_tests/
│   │   └── skill.md
│   ├── git_operations/
│   │   └── skill.md
│   ├── m365_graph_knowledge/
│   │   └── skill.md
│   ├── oauth2_integration/
│   │   └── skill.md
│   ├── powershell_best_practices/
│   │   └── skill.md
│   └── refactor/
│       └── skill.md
├── prompts/               # Reusable prompt templates
├── tools/                 # Helper scripts and utilities
├── templates/             # Templates for creating new skills/prompts
├── config/                # Configuration and defaults
├── context/               # Layer-3 context standards and learning references
└── learnings/             # Post-project reflections and recommendations
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
| **Knowledge Retrieval** | Microsoft 365 and enterprise knowledge retrieval with citations | `m365_graph_knowledge/` |
| **Andis BI Data Engineering** | BI SQL change planning/execution with guardrails | `andis_bi_sql_change/` |

## Contributing

1. Follow the skill template format (`skills/<skill_name>/skill.md`).
2. Keep skills focused — one task per skill.
3. Test your skill by invoking it from VS Code chat.
4. Update `skill_library.md` with the new entry.
5. After completing projects, document learnings in `learnings/` with recommendations for new skills or tool improvements.

## License

Internal use — Andis Company.
