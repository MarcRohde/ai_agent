# Repository Configuration Standard

This standard defines how to configure repositories for layered AI memory and committed lesson loops.

## Objectives

- Make repository intent explicit for agents.
- Keep context usage efficient through layered memory.
- Persist lessons learned in git for compounding quality.

## Layer Model

1. Layer 1: Global instructions in agent settings.
2. Layer 2: Repository mission file (`AGENTS.md` and `CLAUDE.md`) at repo root.
3. Layer 3: Repository context files in `context/`.

## Required Files for Each Repository

1. `AGENTS.md`
2. `CLAUDE.md`
3. `context/README.md`
4. At least one context file with `Header`, `Content`, and `Learning Log` sections

## Mission File Requirements

Include these sections:
- Purpose
- Repository Tree
- Rules
- Note-Taking Loop

Rules must explicitly require:
- reading repository guidance before changes
- logging one-line dated lessons in repository files
- creating a new focused context file when 3 or more similar lessons exist

## Context File Requirements

Each context file must include:
- `## Header`: file purpose and usage conditions
- `## Content`: standards, examples, and constraints
- `## Learning Log`: one-line dated lessons using `- YYYY-MM-DD | lesson`

## Cross-Repository Rule

When work spans `ai_agent` and a project repository:
- update `ai_agent` learnings/context for library-level lessons
- update the project repository mission/context for project-level lessons

## Existing Notes Migration Rule

For repositories with existing notes:
1. Preserve existing files and content.
2. Add standardized sections (`Header`, `Content`, `Learning Log`).
3. Extract key one-line dated lessons into `Learning Log`.
4. Keep notes committed in git.

## Recommended Rollout Steps

1. Scaffold mission files from `templates/repository_agents_template.md`.
2. Scaffold context files from `templates/context_file_template.md`.
3. Register and communicate repository-specific rules in README/docs.
4. Add ongoing lesson updates to normal completion workflow.

## Automation

Use `skills/repository_configuration_scaffold/skill.md` to apply this standard consistently.
