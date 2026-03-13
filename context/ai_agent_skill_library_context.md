# AI Agent Skill Library Context

## Header

Purpose: Define quality standards and recurring patterns for maintaining this skill library.
Use when: Adding or updating skills, prompts, templates, configuration, and supporting tools.

## Content

- Keep skill definitions focused on one primary task.
- Use progressive disclosure in skill instructions: lead with minimum required actions, then provide deeper detail as needed.
- Keep this canonical reference for agent-skill guidance: https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- Register all new skills in `skill_library.md` and `skills/README.md`.
- Keep templates aligned with current skill structure so new skills are consistent by default.
- Prefer reusable configuration and scripts over one-off instructions.
- Capture high-value learnings in `learnings/` and extract repeated patterns into `context/` files.

## Learning Log

- 2026-03-12 | Repository-level mission files plus context files provide better continuity than relying only on global instructions.
- 2026-03-12 | Cross-repo work should update learnings in both ai_agent and the active project repository when both contexts are affected.
- 2026-03-13 | Progressive disclosure should be explicitly enforced in mission files, skill libraries, templates, and context standards.
