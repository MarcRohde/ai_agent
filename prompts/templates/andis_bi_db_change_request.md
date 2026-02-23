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

## Required Approach
1. Confirm Andis BI scope and environment.
2. If target is BI-PROD, do not execute without explicit production approval.
3. Discover current object definitions and dependency chain.
4. Build an ordered plan (stage -> lookup -> fact/dim -> orchestration).
5. Implement only what is required by request.
6. Run validation queries and report exact results.
7. Provide rollback steps for each modified object.

## Required Output Format

### Scope Confirmation
- Environment:
- Databases:
- In scope:
- Out of scope:

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

### Rollback Plan
- Object:
- Rollback SQL/Step:

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
