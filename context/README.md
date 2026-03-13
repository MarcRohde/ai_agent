# Context Directory

This folder stores layer-3 context files that teach agents what good work looks like in this repository.

## Required Structure for Context Files

Each context file should include these sections:
1. `## Header`
2. `## Content`
3. `## Learning Log`

## Learning Log Rules

- Lessons are committed to git.
- Use one-line dated entries.
- Format: `- YYYY-MM-DD | lesson`.
- Keep entries actionable and specific.
- If 3 or more lessons are closely related, create a focused context file and move or summarize those entries there.

## Scope Rules

- `ai_agent` context files capture lessons about skill library operations, tooling, and standards.
- Project repositories should maintain their own `context/` folders and logs for project-specific learnings.
- When working across repositories, update both scopes when both receive new learnings.

## Related Files

- `config/repository_configuration_standard.md`
- `templates/context_file_template.md`
- `skills/repository_configuration_scaffold/skill.md`
