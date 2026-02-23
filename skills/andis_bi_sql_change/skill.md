# Skill: Andis BI SQL Change

## Description
Plan and execute SQL changes specifically for Andis BI environments using controlled sequencing, ETL pattern alignment, and mandatory validation. This skill is scoped to Andis BI databases only and is not intended for non-BI environments.

## Scope
- Applies to: Andis BI environments and databases (for example: `AndisStage`, `AndisODS`, BI-DEV/BI-PROD).
- Does not apply to: non-Andis BI systems, application databases, or unrelated environments.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `change_request` | Yes | Description of the BI SQL change to implement |
| `environment` | Yes | Target environment (`BI-DEV` or `BI-PROD`) |
| `databases` | Yes | Target BI databases (for example `AndisStage`, `AndisODS`) |
| `objects_in_scope` | Yes | Tables/views/procs affected by the change |
| `execution_mode` | No | `plan-only` or `plan-and-execute` (default: `plan-only`) |
| `production_approval` | Conditional | Required when `environment = BI-PROD` |

## Preconditions
1. Confirm the request is explicitly for Andis BI scope.
2. Confirm target environment and database names.
3. If `BI-PROD`, require explicit production approval before execution.
4. Identify comparable existing BI design pattern(s) to mirror (for example reference table load, dimension update, orchestration insertion point).

## Steps

1. **Validate scope and safety**
   - Ensure request is Andis BI-specific.
   - Refuse or pause execution if environment is ambiguous.
   - Require explicit approval for production execution.

2. **Discover current state**
   - Inspect existing BI objects and dependencies.
   - Capture baseline row counts and key lookup integrity before changes.
   - Identify ETL and modeling patterns already used in the BI environment.

3. **Create implementation plan**
   - List ordered object changes (stage -> lookup -> fact/dim -> orchestration).
   - Include rollback approach for each object.
   - Define validation queries and expected outcomes.

4. **Implement in dependency order**
   - Apply SQL changes in the planned sequence.
   - Keep changes minimal and pattern-consistent.
   - Avoid unrelated refactors.

5. **Validate and reconcile**
   - Execute validation queries.
   - Verify row counts, foreign key/lookup mapping, and output surface fields.
   - Confirm there are no orphan mappings introduced by the change.

6. **Report outcome**
   - Provide execution summary, validation results, and any follow-up tasks.
   - Explicitly note environment where changes were applied.

## Output

```markdown
## Andis BI SQL Change Summary

### Scope
- Environment: ...
- Databases: ...
- Objects changed: ...

### Plan
1. ...
2. ...
3. ...

### Changes Applied
- Object: ...
  - Change: ...
  - Pattern aligned with: ...

### Validation
- Query: ...
- Result: ...
- Status: Pass/Fail

### Rollback
- Object: ...
- Rollback step: ...

### Notes
- Risks / follow-ups: ...
```

## Safety Guardrails
- Never execute destructive operations without explicit user confirmation.
- Never run in production without explicit production approval.
- If scope is not Andis BI, stop and recommend a different skill.

## Referenced Prompts
- `prompts/system/default_system.md`
- `prompts/templates/andis_bi_db_change_request.md`

## Referenced Tools
- SQL query execution tooling
- Optional: scripts under `tools/scripts/` for validation automation

## Tags
`andis`, `bi`, `sql`, `etl`, `data-warehouse`, `change-management`
