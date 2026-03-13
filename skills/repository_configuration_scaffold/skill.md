# Skill: Repository Configuration Scaffold

## Description
Configure a repository to use layered memory with mission files, context files, and committed lesson loops. Apply this skill when creating a new repository or migrating an existing repository to the standardized model.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `repository_root` | Yes | Absolute or workspace-relative repository root path |
| `repository_purpose` | Yes | One paragraph describing primary work performed in the repository |
| `top_level_folders` | Yes | List of key folders with purpose notes |
| `existing_notes_paths` | No | Existing notes files that should be reformatted to this model |
| `enable_cross_repo_loop` | No | Whether to enforce dual logging for ai_agent and project repo when both contexts change (default: true) |

## Steps

1. **Create mission files**
   - Add `AGENTS.md` and `CLAUDE.md` at repository root.
   - Include Purpose, Repository Tree, Rules, and Note-Taking Loop sections.
   - Keep requirements explicit for dated one-line lessons.

2. **Create context structure**
   - Add `context/README.md`.
   - Add at least one context file using `templates/context_file_template.md`.
   - Include `Header`, `Content`, and `Learning Log` sections.

3. **Enable lesson loop behavior**
   - Require lesson format: `- YYYY-MM-DD | lesson`.
   - Require creation of a focused context file when 3 or more related lessons accumulate.
   - If `enable_cross_repo_loop` is true, require updates in both `ai_agent` and project repo when both contexts are affected.

4. **Reformat existing notes**
   - Preserve existing note content.
   - Add standardized `Header`, `Content`, and `Learning Log` sections.
   - Extract high-value one-line dated lessons into `Learning Log`.

5. **Update repository documentation**
   - Add references in README and relevant docs to the mission/context files.
   - Confirm notes are intended to be committed in git.

6. **Validate configuration**
   - Confirm required files exist.
   - Confirm loop rules are present in mission file.
   - Confirm at least one context file has learning entries.

## Output

Return a completion summary using this format:

```markdown
## Repository Configuration Complete

**Repository:** {{repository_root}}

### Files Created
- {{path}}

### Files Updated
- {{path}}

### Learning Loop Status
- Mission loop configured: Yes/No
- Context loop configured: Yes/No
- Existing notes reformatted: Yes/No
- Cross-repo loop enabled: Yes/No

### Follow-Up
- {{Any remaining manual steps}}
```

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- `templates/repository_agents_template.md`
- `templates/context_file_template.md`

## Tags
`repository-setup`, `agent-configuration`, `knowledge-management`, `memory-loop`, `documentation`
