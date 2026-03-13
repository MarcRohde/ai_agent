# Templates Directory

This directory contains scaffolding templates for creating new skills, prompts, and other artifacts.

## Available Templates

| Template | Purpose |
|----------|---------|
| `skill_template.md` | Skeleton for a new skill definition |
| `prompt_template.md` | Skeleton for a new prompt template |
| `repository_agents_template.md` | Template for repository mission files (`AGENTS.md` / `CLAUDE.md`) |
| `context_file_template.md` | Template for layer-3 context files with learning logs |

## Usage

### For Skills
1. Create a new folder in `skills/` named after the skill (e.g., `skills/my_skill/`).
2. Copy `skill_template.md` into the folder as `skill.md`.
3. Fill in all sections.
4. Register the skill in `skill_library.md`.

### For Prompts
1. Copy `prompt_template.md` to `prompts/templates/`.
2. Rename it with a descriptive `snake_case` name.
3. Fill in all sections.

### For Repository Scaffolding
1. Copy `repository_agents_template.md` to repo root as `AGENTS.md` and `CLAUDE.md`.
2. Create `context/README.md` and context files using `context_file_template.md`.
3. Add dated one-line lessons to context learning logs as work is completed.
