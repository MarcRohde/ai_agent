# Attribution and Ticketing Standards

**Version:** 1.0
**Last Updated:** March 8, 2026
**Author:** AI Agent / Marc Rohde

---

## Overview

This document establishes standards for attributing AI-assisted work and referencing organizational tracking systems. These standards ensure accountability, proper credit, and consistent integration with Azure DevOps workflows.

---

## 1. Author Attribution Standards

### Principle
All AI-generated or AI-assisted code, scripts, and documentation must attribute work to the human developer who is accountable for the output.

### Format
```
Author: AI Agent / [Developer Name]
```

### Examples
- **For Marc Rohde:** `Author: AI Agent / Marc Rohde`
- **General format:** `Author: AI Agent / [Your Name]`

### Rationale
- **Accountability:** Human developers are responsible for reviewing, validating, and maintaining AI-assisted work
- **Partnership Model:** Attribution reflects the collaborative nature of AI-assisted development
- **Transparency:** Clear attribution helps teams understand the development process
- **Professional Standards:** Maintains integrity in code authorship and documentation

### Application Contexts
- Script headers (SQL, PowerShell, Python)
- Code file comments
- Documentation files (Markdown, text)
- Commit messages
- Pull request descriptions
- Technical design documents

---

## 2. Ticketing System Standards

### Organization Standard
Andis Company uses **Azure DevOps Work Items** for all change tracking, feature requests, and issue management.

### ❌ Never Reference
- "Jira"
- "Jira Tickets"
- "JIRA-####"
- Any other ticketing systems

### ✅ Correct Format
```
Azure DevOps Work Item: [ID or TBD]
```

### Examples
- **With Known ID:** `Azure DevOps Work Item: 12345`
- **Pending Assignment:** `Azure DevOps Work Item: TBD`
- **In Commit Messages:** `feat: Add warehouse alignment logic (Azure DevOps Work Item: 12345)`

### Where to Include References
1. **Script Headers:** Every deployment script, ETL procedure, utility script
2. **Commit Messages:** All git commits related to tracked work
3. **Pull Requests:** PR descriptions and linked work items
4. **Documentation:** Change logs, README updates, architecture docs
5. **Code Comments:** When explaining why a change was made

---

## 3. Script Header Template

### Standard SQL Script Header

```sql
/*
================================================================================
[Script Title - Clear, Descriptive Name]
================================================================================
Environment: [PROD / BI-DEV / UAT / etc]
Date: YYYY-MM-DD
Author: AI Agent / Marc Rohde
Azure DevOps Work Item: [ID or TBD]

PURPOSE:
[Brief description of what this script does and why]

CONTEXT:
[Background information, related changes, dependencies]

CHANGES:
- [Specific change #1]
- [Specific change #2]
- [Specific change #3]

VALIDATION:
[How to verify the changes work correctly]

ROLLBACK:
[How to undo changes if needed, or reference to rollback script]

NOTES:
- [Important considerations]
- [Known limitations or future improvements]
================================================================================
*/
```

### Standard PowerShell Script Header

```powershell
<#
================================================================================
[Script Title - Clear, Descriptive Name]
================================================================================
Environment: [PROD / DEV / UAT]
Date: YYYY-MM-DD
Author: AI Agent / Marc Rohde
Azure DevOps Work Item: [ID or TBD]

.SYNOPSIS
[One-line description]

.DESCRIPTION
[Detailed description of functionality]

.PARAMETER [ParameterName]
[Parameter description]

.EXAMPLE
[Usage example]

.NOTES
- [Important notes]
- Dependencies: [List dependencies]
- Validation: [How to verify]
================================================================================
#>
```

### Standard Python Script Header

```python
"""
================================================================================
[Script Title - Clear, Descriptive Name]
================================================================================
Environment: [PROD / DEV / UAT]
Date: YYYY-MM-DD
Author: AI Agent / Marc Rohde
Azure DevOps Work Item: [ID or TBD]

PURPOSE:
[Brief description]

USAGE:
    python script_name.py [arguments]

DEPENDENCIES:
    - [package1]
    - [package2]

VALIDATION:
    [How to verify output]
================================================================================
"""
```

---

## 4. Documentation Standards

### Change Logs

**Format:**
```markdown
## [Date] - Author: AI Agent / Marc Rohde
**Azure DevOps Work Item:** [ID or TBD]

### Added
- [New feature or capability]

### Changed
- [Modification to existing functionality]

### Fixed
- [Bug fix or correction]

### Deprecated
- [Features being phased out]
```

### Commit Messages

**Format:**
```
<type>(<scope>): <short summary> (Azure DevOps Work Item: [ID])

<optional detailed description>
```

**Examples:**
```
feat(etl): Add WarehouseID to BookingDetail load (Azure DevOps Work Item: 12345)

fix(sql): Correct join condition in factSalesOrder (Azure DevOps Work Item: 12346)

docs(readme): Update deployment procedures (Azure DevOps Work Item: TBD)
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `refactor`: Code restructuring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### README Files

All README files should include:

```markdown
## Authorship and Maintenance

**Primary Author:** AI Agent / Marc Rohde
**Last Updated:** [Date]
**Azure DevOps Work Item:** [ID or TBD]

## Change History

| Date | Author | Work Item | Description |
|------|--------|-----------|-------------|
| YYYY-MM-DD | AI Agent / Marc Rohde | #### | [Change description] |
```

---

## 5. Subagent Usage Preference

### When to Use Subagents

**PREFER using subagents for:**

1. **Parallel Work Streams**
   - Generating multiple independent scripts
   - Creating documentation sets
   - Parallel analysis of different data sources

2. **Context Isolation**
   - Tasks requiring different skill sets
   - Independent validation checks
   - Separate implementation phases

3. **Efficiency Gains**
   - Faster completion through parallelization
   - Reduced context switching
   - Better resource utilization

### Best Practices

**DO:**
- ✅ Launch subagents in parallel when tasks are independent
- ✅ Provide each subagent with focused, specific instructions
- ✅ Review and integrate subagent outputs systematically
- ✅ Use subagents for repetitive but varied tasks

**DON'T:**
- ❌ Use subagents for tightly coupled sequential tasks
- ❌ Create unnecessary subagents for simple operations
- ❌ Launch subagents without clear objectives

### Example Scenarios

**Good Use Cases:**
```
Task: Create 5 deployment scripts for different tables
Approach: Launch 5 subagents in parallel, each generating one script

Task: Generate comprehensive documentation set
Approach: Parallel subagents for API docs, user guide, architecture overview

Task: Validate changes across multiple environments
Approach: Parallel subagents checking DEV, UAT, PROD
```

**Poor Use Cases:**
```
Task: Single script modification
Approach: Direct implementation (no subagent needed)

Task: Sequential steps where step 2 depends on step 1
Approach: Sequential execution (subagents would add overhead)
```

---

## 6. Enforcement and Validation

### Pre-Commit Checklist

Before committing any AI-assisted work:

- [ ] **Attribution verified:** Script/file includes `Author: AI Agent / [Developer Name]`
- [ ] **Work item referenced:** Azure DevOps Work Item ID included or marked TBD
- [ ] **No Jira references:** Confirmed no "Jira" text in changes
- [ ] **Header complete:** All required header sections populated
- [ ] **Documentation updated:** README or change log updated if applicable

### Automated Checks

Use search tools to find violations:

**Check for Jira references:**
```powershell
# PowerShell command to find Jira references
Get-ChildItem -Recurse -Include *.sql,*.ps1,*.py,*.md |
    Select-String -Pattern "jira" -CaseSensitive:$false
```

**Check for missing attribution:**
```powershell
# Find scripts without proper author attribution
Get-ChildItem -Recurse -Include *.sql,*.ps1,*.py |
    Where-Object {
        $content = Get-Content $_.FullName -Raw
        $content -notmatch "Author: AI Agent"
    } | Select-Object FullName
```

### Correction Process

If violations are found:

1. **Identify:** Use search commands to locate all violations
2. **Document:** List files requiring updates
3. **Batch Update:** Use multi-file edit tools for consistency
4. **Verify:** Re-run checks to confirm corrections
5. **Commit:** Commit corrections with appropriate message

---

## 7. Examples and Templates

### Complete SQL Deployment Script Example

```sql
/*
================================================================================
Deploy WarehouseID Alignment - AndisODS Order.BookingDetail
================================================================================
Environment: PROD
Date: 2026-03-08
Author: AI Agent / Marc Rohde
Azure DevOps Work Item: TBD

PURPOSE:
Populate WarehouseID in Order.BookingDetail for recent records where staging
data provides the source code.

CONTEXT:
WarehouseID was added to the ETL process but not backfilled for existing
records. This update aligns recent data (last 4 years) with staging sources.

CHANGES:
- Update Order.BookingDetail.WarehouseID from staging WarehouseCode
- Process only records from last 4 years
- Preserve ETL audit columns during update

VALIDATION:
SELECT COUNT(*) FROM [Order].[BookingDetail]
WHERE WarehouseID IS NOT NULL
  AND ETLCreatedDate >= DATEADD(YEAR, -4, GETDATE());

ROLLBACK:
See 2026-03-08_Rollback_WarehouseID_Alignment.sql

NOTES:
- Batch size: 10,000 rows per transaction
- Estimated runtime: 5-10 minutes
- No impact on active business processes
================================================================================
*/

-- [Script content follows]
```

### Complete Documentation File Example

```markdown
# WarehouseID Alignment Project

**Author:** AI Agent / Marc Rohde
**Date:** March 8, 2026
**Azure DevOps Work Item:** TBD

## Overview

This project aligns WarehouseID values in the AndisODS Order.BookingDetail
table with source data from AndisStage.

[... rest of documentation ...]

## Change History

| Date | Author | Work Item | Description |
|------|--------|-----------|-------------|
| 2026-03-08 | AI Agent / Marc Rohde | TBD | Initial alignment implementation |
```

---

## 8. Quick Reference

### Attribution Format
```
Author: AI Agent / Marc Rohde
```

### Work Item Format
```
Azure DevOps Work Item: [ID or TBD]
```

### Never Use
```
❌ Jira
❌ JIRA-####
❌ Jira Ticket
```

### Always Use
```
✅ Azure DevOps Work Item
✅ Work Item ####
✅ ADO Work Item
```

---

## Revision History

| Date | Author | Work Item | Changes |
|------|--------|-----------|---------|
| 2026-03-08 | AI Agent / Marc Rohde | TBD | Initial standards document created |

---

## Related Documentation

- [Skill Library](../skill_library.md) - AI Agent skill definitions
- [Andis BI DB Change Request Template](../prompts/templates/andis_bi_db_change_request.md) - Change request format
- [SQL Development Standards](../../work-projects/Andis%20BI%20Architecture/AndisODS_ETL_Development_Standards.md) - ETL conventions

---

**For questions or updates to these standards, contact Marc Rohde.**
