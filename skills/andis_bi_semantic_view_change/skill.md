# Skill: Andis BI Semantic View Change

## Description
Plan and execute semantic-layer view updates in Andis BI (`ods.dim*`) with explicit grain protection, deterministic join validation, and source-target reconciliation.

## Scope
- Applies to: Andis BI semantic views (for example `ods.dimCustomer`, `ods.dimContact`, other `ods.dim*` objects).
- Does not apply to: non-BI systems, non-semantic ETL changes, or unrelated databases.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `change_request` | Yes | Description of semantic field change |
| `environment` | Yes | `BI-DEV` or `BI-PROD` |
| `target_view` | Yes | Semantic view to update (for example `ods.dimContact`) |
| `grain_key` | Yes | Grain key that must remain unique |
| `bridge_path` | Conditional | Required if new field is sourced through joins |
| `bridge_determinism_proof` | Yes | Evidence that join path does not fan out grain |
| `execution_mode` | No | `plan-only` or `plan-and-execute` (default: `plan-only`) |
| `production_approval` | Conditional | Required when `environment = BI-PROD` |

## Preconditions
1. Confirm the request is Andis BI semantic-layer scope.
2. Confirm target environment and target view.
3. Capture current view definition and create rollback SQL before deployment.
4. Capture baseline parity metrics:
   - `COUNT(*)`
   - `COUNT(DISTINCT <grain_key>)`
   - duplicate grain query (`GROUP BY <grain_key> HAVING COUNT(*) > 1`)
5. If joined sourcing is required, prove bridge determinism with duplicate/fanout checks.

## Steps

1. **Validate scope and approvals**
   - Ensure request is for Andis BI semantic layer.
   - Require explicit approval for BI-PROD execution.

2. **Run join and grain gate**
   - Define grain key.
   - Validate deterministic bridge path.
   - If deterministic bridge is not possible, require explicit best-effort approval and document risk.

3. **Plan change with rollback-first design**
   - Define exact projection/join changes.
   - Define rollback SQL for `target_view`.
   - Define validation query pack and expected results.

4. **Implement minimal SQL change**
   - Use `CREATE OR ALTER VIEW`.
   - Add only required joins/projections.
   - Preserve existing view behavior outside requested scope.

5. **Validate semantic integrity**
   - Confirm row/grain parity before vs after.
   - Confirm duplicate grain count remains zero.
   - Confirm new field coverage and source-target mismatch metrics.

6. **Report and close**
   - Summarize changes, validations, and rollback path.
   - Explicitly state environment where change was applied.

## Output

```markdown
## Andis BI Semantic View Change Summary

### Scope
- Environment: ...
- Target view: ...
- Grain key: ...

### Join and Grain Gate
- Bridge path: ...
- Determinism proof: Pass/Fail
- Best-effort approved: Yes/No

### Changes Applied
- View: ...
- Projection updates: ...
- Join updates: ...

### Validation
- Row count parity: Pass/Fail
- Distinct grain parity: Pass/Fail
- Duplicate grain rows: ...
- Coverage (%/count): ...
- Source-target mismatch count: ...

### Rollback
- View: ...
- Rollback SQL/step: ...

### Notes
- Risks / follow-ups: ...
```

## Safety Guardrails
- Never deploy semantic-layer joins without explicit grain key and determinism checks.
- Never proceed to production without explicit production approval.
- Never skip rollback script preparation.
- Pause and escalate when join path is ambiguous and no best-effort approval is provided.

## Referenced Prompts
- `prompts/system/default_system.md`
- `prompts/templates/andis_bi_db_change_request.md`

## Referenced Tools
- SQL query execution tooling
- Optional: scripts under `tools/scripts/` for validation automation

## Tags
`andis`, `bi`, `sql`, `semantic-layer`, `dimensional-model`, `data-warehouse`
