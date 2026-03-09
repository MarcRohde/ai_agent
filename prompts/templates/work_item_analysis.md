# Prompt Template: Azure DevOps Work Item Analysis

## Purpose
Guide the agent through analyzing Azure DevOps work items with proper filtering and metrics calculation.

## Template

```
You are analyzing Azure DevOps work items.

**Work Item Type**: {{work_item_type}}
**Project**: {{project_name}}
**Filter Criteria**: {{filter_criteria}}
**Analysis Focus**: {{analysis_focus}}
**Time Period**: {{time_period}}

## Instructions

1. **Query work items** using efficient search methods:
   - Use `mcp_microsoft_azu_search_workitem` with appropriate filters
   - Apply state filters (e.g., Active, New, In Progress) to exclude closed items
   - Filter by work item type explicitly if analyzing a specific type

2. **Filter results precisely**:
   - If analyzing specific work item types, filter by `system.workitemtype` field
   - Do not rely on content search alone - it returns mixed types
   - Example: Search for "help desk" may return 133 items, but only 52 might be actual "Help Desk" work items

3. **Calculate metrics**:
   - Count of items by assignee
   - Average days open per assignee
   - Total days open per assignee
   - Identify longest open items
   - Identify unassigned items

4. **Use analysis script if available**:
   - Check for existing analysis scripts in `work-projects/scripts/`
   - Prefer reusable scripts over one-off calculations
   - Save new analysis scripts for future use

5. **Present results clearly**:
   - Table format for assignee statistics
   - Sorted by relevant metric (e.g., average days open)
   - Highlight key findings and outliers
   - List top longest open items with details

## Output Format

### Summary Statistics
- Total items matching criteria
- Total items after type filtering (if applicable)
- Analysis date
- Date range covered

### Assignee Breakdown
Table showing:
- Assignee name
- Count of assigned items
- Average days open
- Total days open

### Top Longest Open Items
List of 5-10 longest open items with:
- Work item ID
- Title (truncated if needed)
- Days open
- Assignee
- State

### Key Findings
- Notable patterns
- Outliers requiring attention
- Recommendations for action
```

## Variables

| Variable | Description |
|----------|-------------|
| `{{work_item_type}}` | Type to analyze: Help Desk, Bug, User Story, Task, Feature, etc. |
| `{{project_name}}` | Azure DevOps project name (e.g., Dynamics ERP, BI, WebDev) |
| `{{filter_criteria}}` | Additional filters: state, assignee, date range, tags |
| `{{analysis_focus}}` | What to analyze: age trends, assignee workload, priority distribution |
| `{{time_period}}` | Time range for analysis: all time, last 90 days, YTD, etc. |

## Example Usage

### Help Desk Analysis by Assignee
```
Work Item Type: Help Desk
Project: Dynamics ERP
Filter Criteria: State in (Active, New, In Progress)
Analysis Focus: Average days open by assignee
Time Period: All open items
```

### Bug Analysis by Priority
```
Work Item Type: Bug
Project: BI
Filter Criteria: Priority = 1 (Critical), State = Active
Analysis Focus: Count by module/area, age distribution
Time Period: Last 30 days
```

## Related Scripts

- `work-projects/scripts/analyze_helpdesk_items.py` - Help Desk work item analysis by assignee

## Notes

- Always filter by `system.workitemtype` when analyzing specific types
- Content search returns mixed results - type filtering is essential
- Use existing analysis scripts when available to maintain consistency
- Save new analysis logic as reusable scripts for future use
