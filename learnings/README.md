# Learnings

This folder contains post-project reflections, improvement recommendations, and lessons learned from real development work with AI agents.

## Purpose

After completing significant development tasks, capture:
- New skills that should be added to the skill library
- Tool recommendations and enhancements
- Patterns that worked well or poorly
- Time savings and impact estimates
- References to relevant documentation

## File Naming Convention

`{type}-{YYYY-MM-DD}.md`

Examples:
- `recommendations-2026-03-02.md` — Skill and tool recommendations
- `lessons-learned-2026-03-15.md` — General project reflections
- `postmortem-2026-04-01.md` — Post-incident analysis

## When to Create a Learning Document

Create a new learning document when:
- You've completed a multi-hour development project (3+ hours)
- You identified missing skills or tool gaps during development
- You discovered an API integration pattern worth capturing
- You solved a complex problem that others might encounter
- You want to propose improvements to the agent workflow

## Template Structure

```markdown
# {Title}

**Date:** {YYYY-MM-DD}
**Based On:** {Brief project description}

---

## New Skills Added/Recommended

### Skill Name
**Location:** `skills/{skill_name}/skill.md` (if created)

{What gap this skill fills}

**Key Capabilities:**
- {Capability 1}
- {Capability 2}

**Impact:** {Time/quality benefit}

---

## Tool Recommendations

### Tool Name
**Current State:** {What exists today}
**Recommendation:** {Proposed enhancement}

**Benefits:**
- {Benefit 1}

---

## Usage Recommendations

{Guidance on when to use new skills/tools}

---

## Metrics & Impact Estimates

| Scenario | Time Saved | Quality Impact |
|----------|------------|----------------|
| {Use case} | {Hours} | {Improvement %} |

---

## Next Steps

- [ ] {Action item}

---

## References

- [Link to documentation]
```

## Review Cadence

At regular intervals (monthly/quarterly):
1. Review all learning documents
2. Consolidate common patterns into skills
3. Update skill library index
4. Archive outdated learnings

---

**Note:** This folder evolves the skill library based on real-world usage. Keep it updated!
