# Skill: Azure DevOps Work Item Creation

## Description
Create Azure DevOps work items with intelligent project inference, comprehensive descriptions, and proper attachment handling. Ensures work items are created in the correct project based on context and includes all necessary documentation.

## Complexity & Routing

### Task Complexity
- **Simple (Low Cost):** Query work items by assignee name, list open items, retrieve work item details, search by keywords
- **Moderate:** Create work items with standard fields, update existing items, link related items
- **Complex (Consider Escalation):** Bulk work item operations, complex field mappings, cross-project migrations, custom workflow automation

### Cost-Optimization Guidelines
- **Efficient Tools:** Use `mcp_microsoft_azu_search_workitem` for assignee queries (3-5x faster, 60-80% less data)
- **Avoid Inefficient Patterns:** Don't use backlog queries when search API with filters is available
- **Batch Operations:** Use `get_work_items_batch_by_ids` only when full field details are needed
- **Name Resolution:** Leverage assignee lookup table to avoid repeated identity searches
- **Work Item Type Filtering:** When analyzing specific work item types (e.g., "Help Desk"), filter by `system.workitemtype` field, not just content search

### When to Use This Skill Directly
✅ Creating/updating individual work items
✅ Querying work items by assignee (use efficient search method)
✅ Searching work items with filters (state, type, keywords)
✅ Retrieving work item details for user review

### When to Escalate to Complex Agent
❌ Bulk operations (>50 work items)
❌ Complex workflow customization requiring Azure DevOps REST API
❌ Cross-project work item migrations
❌ Custom field mappings or advanced queries requiring multiple API calls

## Scope
- Applies to: All Andis Azure DevOps projects
- Contexts: BI deployments, SQL changes, application features, infrastructure changes, ERP customizations, web development
- Work Item Types: Task, Bug, User Story, Epic, Feature, Help Desk

## Analysis Guidelines

### Help Desk Work Item Analysis
When analyzing "Help Desk" work items:
- **Filter by Type:** Use `system.workitemtype = 'Help Desk'` to get actual Help Desk work items
- **Content vs Type:** Search results may include other work item types that mention "help desk" in descriptions
- **Example:** A search for "help desk" may return 133 results, but only 52 might be actual Help Desk work items
- **Script Location:** Use `work-projects/scripts/analyze_helpdesk_items.py` for detailed analysis by assignee
- **Key Metrics:** Average days open, count by assignee, longest open items

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `title` | Yes | Concise work item title (50-100 chars recommended) |
| `description` | Yes | Detailed description of work to be done |
| `work_item_type` | Yes | Type: `Task`, `Bug`, `User Story`, `Epic`, `Feature` |
| `project_context` | No | Explicit project name OR context keywords for inference |
| `attachments` | No | Array of file paths to attach (scripts, docs, configs) |
| `assigned_to` | No | User email or display name |
| `priority` | No | 1 (Critical), 2 (High), 3 (Medium), 4 (Low) - defaults to 2 |
| `acceptance_criteria` | No | List of criteria for completion |
| `related_work_items` | No | Array of related work item IDs |
| `iteration_path` | No | Sprint/iteration assignment |
| `area_path` | No | Team/area assignment |

## Project Inference Rules

When `project_context` is not explicitly provided, infer the project based on these rules:

### BI Project
**Keywords:** BI, SQL, database, ETL, SSRS, SSAS, SSIS, AndisODS, AndisStage, data warehouse, Power BI, semantic model, fact, dimension
**Scope:** All data warehouse, analytics, and BI reporting work

### Dynamics ERP Project
**Keywords:** ERP, Dynamics, D365, Business Central, NAV, finance, operations, manufacturing, supply chain, ERP customization
**Scope:** ERP implementation and post-implementation support

### WebDev Project
**Keywords:** web, website, API, React, Angular, Node.js, frontend, backend, web service, REST, GraphQL, authentication
**Scope:** Web development projects and applications

### DevHub Project
**Keywords:** infrastructure, DevOps, CI/CD, Azure resources, deployment pipeline, general IT, cross-cutting
**Scope:** Primary project for general managed work items and infrastructure

### Default Fallback
If no clear inference can be made, use **Dynamics ERP** as the default project and log a warning for user confirmation.

## Preconditions

1. **Validate project inference** — If project is inferred (not explicit), confirm with the user before creating.
2. **Check for existing similar work items** — Search for duplicates in the target project.
3. **Prepare attachments** — Verify all attachment file paths exist.
4. **Validate required fields** — Ensure title, description, and work_item_type are provided.
5. **Skip tags by default** — Do not set or update `System.Tags` unless the user explicitly requests tags.

## Steps

### 1. **Determine Target Project**
   - If `project_context` is an explicit project name → use it directly
   - If `project_context` contains inference keywords → apply inference rules
   - If no context provided → analyze the `title` and `description` for keywords
   - If still ambiguous → default to **Dynamics ERP** and warn user
   - List available projects: BI, Dynamics ERP, WebDev, DevHub, LSPM, CTA_BT, BI Synapse

### 2. **Build Comprehensive Description**
   Include these sections when applicable:

   ```markdown
   ## Purpose
   {High-level goal of this work item}

   ## Intended Outcomes
   {Specific deliverables and results}

   ## Context
   {Background information, why this is needed}

   ## Implementation Details
   {Technical approach, steps, or specifications}

   ## Acceptance Criteria
   - [ ] Criterion 1
   - [ ] Criterion 2
   - [ ] Criterion 3

   ## Dependencies
   {Related work items, prerequisites, blockers}

   ## Validation & Testing
   {How to verify completion}

   ## Rollback Plan
   {If applicable - how to revert changes}

   ## Documentation
   {Links to related docs, scripts, or resources}
   ```

### 3. **Prepare Field Mappings**
   Map inputs to Azure DevOps field schema:

   | Input Field | ADO Field Name | Format |
   |-------------|----------------|---------|
   | `title` | `System.Title` | Plain text |
   | `description` | `System.Description` | HTML |
   | `work_item_type` | `workItemType` | Parameter |
   | `assigned_to` | `System.AssignedTo` | User reference |
   | `priority` | `Microsoft.VSTS.Common.Priority` | Integer |
   | `iteration_path` | `System.IterationPath` | Path string |
   | `area_path` | `System.AreaPath` | Path string |

### 4. **Resolve Assignee Identity Cross-Reference Fields**
   Normalize assignee identity into reusable fields for downstream matching/reporting:

   - Preferred source (object form): `System.AssignedTo.displayName`, `System.AssignedTo.uniqueName`
   - Fallback source (string form): `System.AssignedTo = "Display Name <email@domain>"`

   Normalization rules:
   1. `assignee_email`: use `uniqueName` when object form exists; otherwise parse text between `<` and `>`.
   2. `assignee_display_name`: use `displayName` when object form exists; otherwise parse text before `<`.
   3. `assignee_first_name` and `assignee_last_name`:
      - If display name contains a comma (for example `Last, First`), split on comma and map accordingly.
      - Else split on whitespace and use first token as first name and last token as last name.

### 5. **Format Description as HTML**
   - Convert markdown to HTML for `System.Description` field
   - Use proper HTML tags: `<h2>`, `<h3>`, `<p>`, `<ul>`, `<li>`, `<code>`, `<pre>`, `<hr>`
   - Preserve code blocks with `<pre><code>` tags
   - Use `<strong>` and `<em>` for emphasis
   - Convert checkboxes: `- [ ]` → `☐` or `<input type="checkbox">`

### 6. **Prepare Attachments**
   For SQL deployments or code changes:
   - Attach all production scripts in execution order
   - Include README/deployment guide files
   - Include validation/rollback scripts
   - Add checklists or runbooks

   Note: Use absolute Windows paths with double backslashes or single forward slashes

### 7. **Create Work Item**
   - Call `mcp_microsoft_azu_wit_create_work_item` with prepared fields
   - Capture work item ID and URL from response
   - Log creation confirmation

### 8. **Post-Creation Actions**
   - Display work item URL for immediate access
   - List any attachments that need manual upload (if tool limitations exist)
   - Provide next steps (e.g., "Assign to reviewer", "Link to PR", "Add to sprint")

## Output

```markdown
✅ **Azure DevOps Work Item Created**

**Work Item ID:** #{id}
**Title:** {title}
**Type:** {work_item_type}
**Project:** {project_name}
**State:** New
**Priority:** {priority}

**URL:** {work_item_url}

### Attached Files
- ✅ {filename1}
- ✅ {filename2}
- ⚠️ {filename3} - Manual upload required

### Next Steps
1. Review work item at URL above
2. {context-specific next step}
3. {context-specific next step}
```

## Advanced Features

### For SQL Deployment Work Items
When creating work items for SQL deployments:
1. **Structure description** with deployment steps (Step 1, 2, 3)
2. **Include validation gates** (hard and soft gates)
3. **Add pre-deployment checklist** with environment prep
4. **Provide post-deployment validation** queries
5. **Document rollback procedures** for each step
6. **List success criteria** with measurable outcomes

### For Bug Reports
When creating bug work items:
1. **Reproduction steps** — Clear step-by-step to reproduce
2. **Expected vs Actual** — What should happen vs what happens
3. **Environment details** — Where the bug occurs
4. **Error messages** — Full stack traces or error text
5. **Screenshots** — Visual evidence if applicable
6. **Severity assessment** — Impact and urgency
7. **Workaround** — Temporary fix if available

### For Feature Requests
When creating feature/user story work items:
1. **User story format** — "As a [user], I want [feature] so that [benefit]"
2. **Business value** — Why this matters
3. **User scenarios** — How users will interact
4. **Technical considerations** — Architecture/design notes
5. **Mockups/wireframes** — UI/UX references if applicable
6. **Definition of Done** — Clear completion criteria

## Field Reference

### Standard Fields Available
Most Azure DevOps work items support these fields:
- `System.Title` — Title (required, max 255 chars)
- `System.Description` — Description (HTML format)
- `System.AssignedTo` — Assigned user
- `System.State` — New/Active/Resolved/Closed
- `System.Reason` — Reason for state
- `System.Tags` — Semicolon-separated tags (excluded by default; set only when explicitly requested)
- `System.AreaPath` — Area/team path
- `System.IterationPath` — Sprint/iteration path
- `Microsoft.VSTS.Common.Priority` — 1-4 priority
- `Microsoft.VSTS.Common.Severity` — 1-4 severity (bugs)
- `Microsoft.VSTS.Scheduling.StoryPoints` — Effort estimate
- `Microsoft.VSTS.Scheduling.OriginalEstimate` — Time estimate (hours)
- `Microsoft.VSTS.Common.AcceptanceCriteria` — Acceptance criteria (HTML)

### Assignee Identity Cross-Reference Fields
Use these normalized fields whenever assignee identity must be matched across work items, comments, and external systems:

| Canonical Field | Primary Source | Fallback Source | Notes |
|-----------------|----------------|-----------------|-------|
| `assignee_email` | `System.AssignedTo.uniqueName` | parse from `System.AssignedTo` string (`<email>`) | Primary key for matching |
| `assignee_first_name` | parse from `System.AssignedTo.displayName` | parse from name portion of string value | Support `Last, First` and `First Last` formats |
| `assignee_last_name` | parse from `System.AssignedTo.displayName` | parse from name portion of string value | Use last token when no comma exists |
| `assignee_display_name` | `System.AssignedTo.displayName` | name portion before `<email>` | Preserve original capitalization |

Observed assignees from Dynamics ERP work items changed in the last 6 months (current staff):

| Email | First Name | Last Name |
|-------|------------|-----------|
| `dbarajas@andisco.com` | `Diego` | `Barajas` |
| `dbatterman@andisco.com` | `Dakota` | `Batterman` |
| `adiefenbach@andisco.com` | `Amanda` | `Diefenbach` |
| `kgilman@andisco.com` | `Kyle` | `Gilman` |
| `tjacobs@andisco.com` | `Tanner` | `Jacobs` |
| `tjones@andisco.com` | `Terrie` | `Jones` |
| `mjones-rinehart@andisco.com` | `Mica` | `Jones-Rinehart` |
| `jkonicek@andisco.com` | `Jason` | `Konicek` |
| `plawson@andisco.com` | `Paul` | `Lawson` |
| `jlemke@andisco.com` | `Jon` | `Lemke` |
| `nloose@andisco.com` | `Nick` | `Loose` |
| `bmcintosh@andisco.com` | `Bobby` | `McIntosh` |
| `apetersen@andisco.com` | `Ashley` | `Petersen` |
| `kprochaska@andisco.com` | `Karin` | `Prochaska` |
| `drawls@andisco.com` | `Derek` | `Rawls` |
| `mschmidt@andisco.com` | `Matthew` | `Schmidt` |
| `bschalk@andisco.com` | `Brian` | `Schalk` |
| `Tariq.Sheikh@mcaconnect.com` | `Tariq` | `Sheikh` |
| `Jterletzky@andisco.com` | `Judy` | `Terletzky` |
| `jtouve@andisco.com` | `Jessica` | `Touve` |
| `rtringali@andisco.com` | `Rick` | `Tringali` |

### Custom Fields
Check project-specific custom fields using:
```powershell
# List available fields for a project
az boards field list --org https://dev.azure.com/andis-code --project "BI"
```

## Querying Work Items by Assignee

### Efficient Workflow for Finding Work Items by Name

When a user requests work items for a specific person (by first name, last name, or full name):

#### Step 1: Resolve Assignee Identity
- If user provides an email address → use it directly
- If user provides a partial name (first or last) → look up email from the assignee table above
- If user provides full name → look up email from the assignee table above
- If multiple matches exist → ask user to clarify

#### Step 2: Query Work Items Using Search Tool
Use `mcp_microsoft_azu_search_workitem` with the following approach:

**Most Efficient (Recommended):**
```
searchText: "assignedTo:email@domain.com"
project: ["Dynamics ERP"]  // or appropriate project
state: ["New", "Active", "Committed", "In Progress", "Ready", "Resolved"]  // exclude "Closed" for active items
top: 50  // adjust based on expected result size
```

**Alternative (works but less precise):**
```
searchText: "assignedTo:FirstName"  // or "assignedTo:LastName"
```

**Example:**
```
User asks: "Show me Mica's open work items"
Action: Look up email → mjones-rinehart@andisco.com
Query: searchText="assignedTo:mjones-rinehart@andisco.com", state=["New","Active"], top=50
```

#### Step 3: Format Results
Present work items in a user-friendly table:

| ID | State | Type | Title | Changed Date |
|----|-------|------|-------|--------------|
| ... | ... | ... | ... | ... |

Include summary statistics:
- Total active items
- State breakdown
- Key work areas (if patterns emerge)

### Performance Comparison

**❌ Inefficient Approach (OLD):**
1. Query entire project backlog → 473+ items (46-56KB response)
2. Batch retrieve 200 items at a time with full field details (82KB+ per batch)
3. Client-side filter by assignee email
4. Multiple API calls required

**✅ Efficient Approach (RECOMMENDED):**
1. Single `mcp_microsoft_azu_search_workitem` call with assignee filter
2. Returns only matching work items (typically 10-50 items, 20-50KB response)
3. Server-side filtering via Azure DevOps search index
4. Supports state filtering to exclude closed items
5. Single API call, minimal data transfer

**Performance Gain:** 3-5x faster, 60-80% less data transfer

### Troubleshooting

**Issue:** Search returns 0 results with email in `assignedTo` parameter array
**Solution:** Don't use the `assignedTo` parameter; use `searchText:"assignedTo:email"` instead

**Issue:** User provides nickname or partial name
**Solution:** Reference the assignee table to map common names to canonical email addresses

**Issue:** Need to search across multiple projects
**Solution:** Include multiple project names in `project` array parameter, or omit to search organization-wide

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- `mcp_microsoft_azu_wit_create_work_item` — Create work item
- `mcp_microsoft_azu_core_list_projects` — List available projects
- `mcp_microsoft_azu_wit_get_work_item` — Validate work item creation
- `mcp_microsoft_azu_search_workitem` — **Primary tool for querying work items by assignee** (most efficient)
- `mcp_microsoft_azu_wit_my_work_items` — ⚠️ Deprecated for assignee queries (only returns current user's items)
- `mcp_microsoft_azu_wit_get_work_items_batch_by_ids` — Retrieve full field details for specific work item IDs
- `mcp_microsoft_azu_wit_list_backlog_work_items` — Query project/team backlog (use sparingly, returns large datasets)
- `mcp_microsoft_azu_core_list_project_teams` — List teams within a project

## Tags
`azure-devops`, `work-items`, `project-management`, `automation`, `ado`
