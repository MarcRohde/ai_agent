# Skill Library — Master Index

> This file is the registry of all available skills. AI agents should read this file to discover what skills are available.

## How to Use

Search this index by **category** or **skill name** to find the right skill, then read the linked skill file for full instructions.

---

## Skills

### Code Quality

| Skill | File | Description |
|-------|------|-------------|
| Code Review | [skills/code_review.md](skills/code_review.md) | Perform a structured code review with actionable feedback |
| Refactor | [skills/refactor.md](skills/refactor.md) | Refactor code for readability, performance, or pattern compliance |

### Testing

| Skill | File | Description |
|-------|------|-------------|
| Generate Tests | [skills/generate_tests.md](skills/generate_tests.md) | Generate unit tests for a given file or function |

### Documentation

| Skill | File | Description |
|-------|------|-------------|
| Documentation | [skills/documentation.md](skills/documentation.md) | Generate or update documentation for code, APIs, or projects |

### Explanation

| Skill | File | Description |
|-------|------|-------------|
| Explain Code | [skills/explain_code.md](skills/explain_code.md) | Explain what a piece of code does, its patterns, and trade-offs |

### Git & Workflow

| Skill | File | Description |
|-------|------|-------------|
| Git Operations | [skills/git_operations.md](skills/git_operations.md) | Common git workflows: branching, commits, PR descriptions |

### Productivity & Communication

| Skill | File | Description |
|-------|------|-------------|
| Outlook Mailbox | [skills/outlook_mailbox.md](skills/outlook_mailbox.md) | Read, search, send, reply, and summarize Outlook emails via Microsoft Graph |

---

## Adding a New Skill

1. Create a new `.md` file in `skills/` using `templates/skill_template.md`.
2. Add a row to the appropriate category table above.
3. If a new category is needed, add a new `###` section.
