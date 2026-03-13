# AGENTS.md

## Purpose
This repository is a reusable skill library for AI coding agents. Use it to provide consistent, versioned execution patterns that can be applied across projects.

## Repository Tree
- `skills/`: task skills and execution workflows
- `prompts/`: system and task templates
- `tools/`: helper scripts
- `templates/`: scaffolding templates
- `config/`: runtime and behavior configuration
- `context/`: layer-3 context standards and reusable quality references
- `learnings/`: committed lesson logs and post-project learnings

## Rules
1. Read `skill_library.md` before selecting a skill.
2. Apply skill precedence: active project repo overrides workspace libraries, which override this repo.
3. Use progressive disclosure in instructions, skills, and docs: present the minimum required actions first, then reveal deeper detail only as needed.
4. Keep this canonical reference for agent-skill guidance: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
5. Use existing style and conventions; avoid unrelated edits.
6. Confirm destructive operations unless explicitly authorized.
7. Keep lessons learned in git for traceability and compounding quality.
8. When this repo is used alongside project repos, enforce note-taking loops at both levels:
   - `ai_agent` level: update relevant files in `learnings/` and `context/`.
   - active project repo level: update that repo's mission/context note files.

## Note-Taking Loop
- After substantive work, add dated one-line lessons to the appropriate learning/context file.
- Preferred format: `- YYYY-MM-DD | lesson`.
- Keep lessons specific, actionable, and scoped to the repo context.
- If a file accumulates 3 or more similar lessons, create a focused context file for that topic and move or summarize those lessons there.
- When new context files are added, update the repository indexes.

## Implementation Standard
For repository setup and migration to this model, follow:
- `config/repository_configuration_standard.md`
- `skills/repository_configuration_scaffold/skill.md`
- `templates/repository_agents_template.md`
- `templates/context_file_template.md`
