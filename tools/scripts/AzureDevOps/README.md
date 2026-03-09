# Azure DevOps Scripts

This directory contains utility scripts for analyzing and managing Azure DevOps work items.

## Scripts

### Analyze-HelpDeskItems.py

Analyzes Azure DevOps Help Desk work items by assignee, calculating metrics such as average days open, total count, and identifying longest open items.

**Usage:**
```powershell
python tools/scripts/AzureDevOps/Analyze-HelpDeskItems.py <json_file_path> [analysis_date]
```

**Arguments:**
- `json_file_path`: Path to JSON file containing Azure DevOps work item query results (required)
- `analysis_date`: Optional date for analysis in YYYY-MM-DD format (defaults to today)

**Examples:**
```powershell
# Analyze with today's date
python tools/scripts/AzureDevOps/Analyze-HelpDeskItems.py results.json

# Analyze with specific date
python tools/scripts/AzureDevOps/Analyze-HelpDeskItems.py results.json 2026-03-08
```

**Workflow:**
1. Query Azure DevOps work items using `mcp_microsoft_azu_search_workitem`
2. Save results to a JSON file (the tool outputs to a temp file automatically)
3. Run this script with the JSON file path
4. Review metrics and identify items needing attention

**Output:**
- Summary statistics (total Help Desk items, analysis date)
- Assignee breakdown table (count, average days open, total days)
- Top 10 longest open Help Desk items

**Notes:**
- Script filters by `system.workitemtype = 'Help Desk'` to exclude other work item types
- Handles timezone-aware datetime parsing from Azure DevOps API
- Sorts by average days open (descending) to highlight workload and aging issues

---

## Related Documentation

- **Skill:** [azure_devops_work_item](../../skills/azure_devops_work_item/skill.md)
- **Template:** [work_item_analysis](../../prompts/templates/work_item_analysis.md)
- **Learnings:** [recommendations-2026-03-08](../../learnings/recommendations-2026-03-08.md)
