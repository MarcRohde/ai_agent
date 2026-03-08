# Prompt Template: Andis BI DB Change Request

## Purpose
Guide BI-specific SQL changes for Andis environments with explicit scope, sequencing, validation, and rollback requirements.

## Template

```
You are handling an Andis BI SQL change request.

## Scope
- System Scope: Andis BI only
- Target Environment: {{environment}}
- Target Databases: {{databases}}
- In Scope Objects: {{objects_in_scope}}
- Out of Scope: Non-Andis BI environments and non-BI systems

## Request
{{change_request}}

## Constraints
- Execution Mode: {{execution_mode}}   # plan-only | plan-and-execute
- Production Approval: {{production_approval}}
- Pattern to Mirror: {{pattern_to_mirror}}
- Change Window / Timing: {{change_window}}
- Grain Key (semantic layer): {{grain_key}}
- Bridge Path (if joined lookup): {{bridge_path}}
- Bridge Determinism Proof: {{bridge_determinism_proof}}
- Backfill Required: {{backfill_required}}
- Backfill SQL: {{backfill_sql}}
- Pre-Deploy Baseline Queries: {{pre_deploy_baseline_queries}}
- Post-Deploy Validation Queries: {{post_deploy_validation_queries}}
- Rollback Script Path: {{rollback_script_path}}

## Required Approach
1. Confirm Andis BI scope and environment.
2. If target is BI-PROD, do not execute without explicit production approval.
3. Discover current object definitions and dependency chain.
4. Capture baseline row/grain metrics before changes.
5. For `ods.dim*` changes, enforce semantic layer join gate:
	- define `grain_key`
	- prove deterministic `bridge_path`
	- run duplicate/fanout checks
6. Build an ordered plan (stage -> lookup -> fact/dim -> orchestration).
7. Implement only what is required by request.
8. If incremental ETL pattern implies historical rows are missed, include one-time backfill.
9. Run validation queries and report exact expected vs actual results.
10. Provide rollback steps and rollback script path for each modified object.
11. For BI-PROD, include explicit deployment evidence (column present, grain parity, mismatch count).

## Required Output Format

### Scope Confirmation
- Environment:
- Databases:
- In scope:
- Out of scope:

### Join and Grain Gate
- Grain key:
- Bridge path:
- Determinism proof status:
- Best-effort approved (if needed):

### Implementation Plan
1. ...
2. ...
3. ...

### SQL Changes Applied
- Object:
- Action:
- Why:

### Validation Results
- Query:
- Expected:
- Actual:
- Status:

### Backfill Results (if applicable)
- Backfill SQL/Step:
- Rows updated:
- Residual mismatch count:

### Rollback Plan
- Object:
- Rollback SQL/Step:
- Rollback script path:

### Production Evidence (if BI-PROD)
- Column exists:
- Row/grain parity:
- Mismatch count:

### Final Status
- Completed / Blocked
- Risks / follow-ups
```

## Variables

| Variable | Description |
|----------|-------------|
| `{{environment}}` | BI target environment (`BI-DEV` or `BI-PROD`) |
| `{{databases}}` | Target Andis BI databases |
| `{{objects_in_scope}}` | Tables/views/procs/functions to update |
| `{{change_request}}` | The requested BI SQL change |
| `{{execution_mode}}` | `plan-only` or `plan-and-execute` |
| `{{production_approval}}` | Explicit production approval text if BI-PROD |
| `{{pattern_to_mirror}}` | Existing ETL/modeling pattern to follow |
| `{{change_window}}` | Planned execution timing/window |
| `{{grain_key}}` | Grain key for semantic-layer changes (`ods.dim*`) |
| `{{bridge_path}}` | Join path used to source new field |
| `{{bridge_determinism_proof}}` | Summary of duplicate/fanout checks |
| `{{backfill_required}}` | Whether one-time historical backfill is required |
| `{{backfill_sql}}` | Backfill SQL statement/procedure call |
| `{{pre_deploy_baseline_queries}}` | Baseline query pack before deployment |
| `{{post_deploy_validation_queries}}` | Validation query pack after deployment |
| `{{rollback_script_path}}` | Path to rollback script |
