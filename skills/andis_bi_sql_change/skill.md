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
| `grain_key` | Conditional | Required for semantic-layer changes (`ods.dim*`) |
| `bridge_path` | Conditional | Required when adding fields through cross-object joins |
| `bridge_determinism_proof` | Conditional | Required for semantic-layer changes; include duplicate/fanout checks |
| `backfill_required` | No | `true` or `false`; required for new columns added to incremental loads |
| `backfill_sql` | Conditional | Required when `backfill_required = true` |
| `pre_deploy_baseline_queries` | No | Query pack for row/grain baseline and coverage checks |
| `post_deploy_validation_queries` | No | Query pack for parity, coverage, and mismatch checks |
| `rollback_script_path` | No | Path to explicit rollback SQL script |
| `execution_mode` | No | `plan-only` or `plan-and-execute` (default: `plan-only`) |
| `production_approval` | Conditional | Required when `environment = BI-PROD` |

## Preconditions
1. Confirm the request is explicitly for Andis BI scope.
2. Confirm target environment and database names.
3. If `BI-PROD`, require explicit production approval before execution.
4. Identify comparable existing BI design pattern(s) to mirror (for example reference table load, dimension update, orchestration insertion point).
5. For semantic-layer changes (`ods.dim*`), define grain key and bridge path before implementation.
6. Capture current object definition and create explicit rollback SQL before execution.

## Steps

1. **Validate scope and safety**
   - Ensure request is Andis BI-specific.
   - Refuse or pause execution if environment is ambiguous.
   - Require explicit approval for production execution.

2. **Discover current state**
   - Inspect existing BI objects and dependencies.
   - Capture baseline row counts and key lookup integrity before changes.
   - Identify ETL and modeling patterns already used in the BI environment.

3. **Run semantic layer join gate (mandatory for `ods.dim*`)**
   - Define explicit grain key (for example `CustomerID`, `ContactID`).
   - Prove join determinism with pre-change checks:
     - `COUNT(*)` and `COUNT(DISTINCT <grain_key>)`
     - duplicate grain check (`GROUP BY <grain_key> HAVING COUNT(*) > 1`)
     - bridge duplicate check on join key path
   - If determinism cannot be proven, stop and request either:
     - a deterministic bridge design, or
     - explicit user approval for best-effort semantics with documented risk.

4. **Create implementation plan**
   - List ordered object changes (stage -> lookup -> fact/dim -> orchestration).
   - Include rollback approach for each object.
   - Define validation queries and expected outcomes.
   - For semantic changes, include fanout prevention and mismatch checks.

5. **Apply pattern-aware backfill rule**
   - For incremental patterns (especially Pattern D / `SinkModifiedOn`-driven loads), do not assume historical rows will populate new columns.
   - Add one-time backfill SQL when required.
   - Validate backfill completion with explicit mismatch counts.

6. **Implement in dependency order**
   - Apply SQL changes in the planned sequence.
   - Keep changes minimal and pattern-consistent.
   - Avoid unrelated refactors.

7. **Validate and reconcile**
   - Execute validation queries.
   - Verify row counts, grain parity, foreign key/lookup mapping, and output surface fields.
   - Confirm there are no orphan mappings or source-target mismatches introduced by the change.

8. **Enforce production deployment contract (`BI-PROD`)**
   - Require explicit production approval text.
   - Use environment-specific deployment script(s) (for example `*-PROD.sql`).
   - Capture post-deploy evidence: column presence, row/grain parity, mismatch count.
   - Clean temporary execution artifacts after evidence capture.

9. **Report outcome**
   - Provide execution summary, validation results, rollback location, and any follow-up tasks.
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
- Expected: ...
- Result: ...
- Status: Pass/Fail

### Grain and Join Gate
- Grain key: ...
- Bridge path: ...
- Determinism proof: Pass/Fail
- Best-effort approved: Yes/No

### Rollback
- Object: ...
- Rollback SQL/step: ...

### Production Evidence (if BI-PROD)
- Column exists: ...
- Row/grain parity: ...
- Mismatch count: ...

### Notes
- Risks / follow-ups: ...
```

## Safety Guardrails
- Never execute destructive operations without explicit user confirmation.
- Never run in production without explicit production approval.
- Never implement `ods.dim*` joins without explicit grain definition and determinism proof.
- Never skip rollback script generation for view/procedure changes.
- If scope is not Andis BI, stop and recommend a different skill.

## Referenced Prompts
- `prompts/system/default_system.md`
- `prompts/templates/andis_bi_db_change_request.md`

## Referenced Tools
- SQL query execution tooling
- Optional: scripts under `tools/scripts/` for validation automation

## Tags
`andis`, `bi`, `sql`, `etl`, `data-warehouse`, `change-management`
