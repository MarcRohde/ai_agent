# Skill Library — Master Index

> This file is the registry of all available skills. AI agents should read this file to discover what skills are available.

## How to Use

Search this index by **category** or **skill name** to find the right skill, then read the linked skill file for full instructions.

---

## Skills

### Code Quality

| Skill | File | Description |
|-------|------|-------------|
| Code Review | [skills/code_review/skill.md](skills/code_review/skill.md) | Perform a structured code review with actionable feedback |
| Refactor | [skills/refactor/skill.md](skills/refactor/skill.md) | Refactor code for readability, performance, or pattern compliance |

### Testing

| Skill | File | Description |
|-------|------|-------------|
| Generate Tests | [skills/generate_tests/skill.md](skills/generate_tests/skill.md) | Generate unit tests for a given file or function |

### Documentation

| Skill | File | Description |
|-------|------|-------------|
| Documentation | [skills/documentation/skill.md](skills/documentation/skill.md) | Generate or update documentation for code, APIs, or projects |

### Explanation

| Skill | File | Description |
|-------|------|-------------|
| Explain Code | [skills/explain_code/skill.md](skills/explain_code/skill.md) | Explain what a piece of code does, its patterns, and trade-offs |

### Git & Workflow

| Skill | File | Description |
|-------|------|-------------|
| Git Operations | [skills/git_operations/skill.md](skills/git_operations/skill.md) | Common git workflows: branching, commits, PR descriptions |

---

## Adding a New Skill

1. Create a new folder in `skills/` named after the skill (e.g., `skills/my_skill/`).
2. Add a `skill.md` file inside the folder using `templates/skill_template.md`.
3. Add a row to the appropriate category table above.
4. If a new category is needed, add a new `###` section.
