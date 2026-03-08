# AI Agent Improvements - Based on Andis BI SQL Semantic Changes

**Date:** March 7, 2026
**Based On:** End-to-end BI-DEV and BI-PROD SQL rollout for `CustomerType` across stage/ETL and semantic views (`ods.dimCustomer` rollback, `ods.dimContact` final implementation)

---

## New Skills Added/Recommended

### 1. Andis BI Semantic View Change
**Location:** `skills/andis_bi_semantic_view_change/skill.md`

Adds a dedicated workflow for `ods.dim*` updates with strict grain protection and deterministic join requirements.

**Key Capabilities:**
- Mandatory grain gate and fanout checks before semantic view changes
- Deterministic bridge validation for joined attributes
- Source-target mismatch validation as a deployment gate
- Rollback-first execution pattern for view updates

**Impact:** Prevents high-risk semantic regressions and reduces rework when join paths are ambiguous.

---

## Existing Skill Enhancements

### 1. Andis BI SQL Change Guardrail Expansion
**Location:** `skills/andis_bi_sql_change/skill.md`

Expanded to include:
- Semantic layer join gate for `ods.dim*` updates
- Pattern-aware backfill requirements for incremental ETL patterns
- Rollback-first requirement for view/procedure updates
- Production deployment evidence contract

**Impact:** Improves repeatability across BI-DEV and BI-PROD deployments and enforces evidence-based releases.

---

## Prompt Template Enhancements

### 1. Andis BI DB Change Request Template
**Location:** `prompts/templates/andis_bi_db_change_request.md`

Added planning fields:
- `grain_key`
- `bridge_path`
- `bridge_determinism_proof`
- `backfill_required`
- `backfill_sql`
- `pre_deploy_baseline_queries`
- `post_deploy_validation_queries`
- `rollback_script_path`

Added required output sections for:
- Join and grain gate
- Backfill results
- Production evidence

**Impact:** Raises planning quality before execution and reduces ambiguity during production rollout.

---

## Lessons Learned from This SQL Work

1. Validate join determinism before semantic edits
- The initial `ods.dimCustomer` path was ambiguous; deterministic bridge proof should gate implementation.

2. Keep enrichment at the correct grain
- `CustomerType` was ultimately correct in `ods.dimContact` using `CE.Contact.AccountID -> crm.account.Id`.

3. Always create rollback scripts before deployment
- Fast rollback enabled safe pivot from `dimCustomer` to `dimContact`.

4. Treat source-target mismatch checks as release criteria
- `MismatchCount = 0` is a clear, objective post-deploy pass condition.

5. Clean temporary artifacts after validation
- Remove `_tmp` files after evidence capture to keep repository clean.

---

## Validation Snapshot (Observed)

### BI-DEV (`ods.dimContact`)
- Row/grain parity: `581,399` rows and `581,399` distinct `ContactID`
- Duplicate grain rows: `0`
- Coverage: `4,035` rows with `AccountID`, `3,610` rows with non-null `CustomerType`
- Source-target mismatches: `0`

### BI-PROD (`ods.dimContact`)
- Row/grain parity: `589,116` rows and `589,116` distinct `ContactID`
- Duplicate grain rows: `0`
- Coverage: `4,379` rows with `AccountID`, `3,641` rows with non-null `CustomerType`
- Source-target mismatches: `0`

---

## Next Steps

1. Add a standard SQL validation query pack template for semantic-layer changes.
2. Consider adding a helper script/tool to export current object definitions and generate rollback scripts automatically.
3. Add team checklist language requiring grain and bridge fields for all `ods.dim*` change requests.

---

## References

- `skills/andis_bi_sql_change/skill.md`
- `skills/andis_bi_semantic_view_change/skill.md`
- `prompts/templates/andis_bi_db_change_request.md`
- `work-projects/scripts/SQL/Add-CustomerType-To-ods-dimContact.sql`
- `work-projects/scripts/SQL/Add-CustomerType-To-ods-dimContact-PROD.sql`
