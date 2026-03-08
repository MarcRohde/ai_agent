# Skill: Azure DevOps Work Item Creation

## Description
Create Azure DevOps work items with intelligent project inference, comprehensive descriptions, and proper attachment handling. Ensures work items are created in the correct project based on context and includes all necessary documentation.

## Scope
- Applies to: All Andis Azure DevOps projects
- Contexts: BI deployments, SQL changes, application features, infrastructure changes, ERP customizations, web development
- Work Item Types: Task, Bug, User Story, Epic, Feature

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

### 4. **Format Description as HTML**
   - Convert markdown to HTML for `System.Description` field
   - Use proper HTML tags: `<h2>`, `<h3>`, `<p>`, `<ul>`, `<li>`, `<code>`, `<pre>`, `<hr>`
   - Preserve code blocks with `<pre><code>` tags
   - Use `<strong>` and `<em>` for emphasis
   - Convert checkboxes: `- [ ]` → `☐` or `<input type="checkbox">`

### 5. **Prepare Attachments**
   For SQL deployments or code changes:
   - Attach all production scripts in execution order
   - Include README/deployment guide files
   - Include validation/rollback scripts
   - Add checklists or runbooks

   Note: Use absolute Windows paths with double backslashes or single forward slashes

### 6. **Create Work Item**
   - Call `mcp_microsoft_azu_wit_create_work_item` with prepared fields
   - Capture work item ID and URL from response
   - Log creation confirmation

### 7. **Post-Creation Actions**
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

### Custom Fields
Check project-specific custom fields using:
```powershell
# List available fields for a project
az boards field list --org https://dev.azure.com/andis-code --project "BI"
```

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- `mcp_microsoft_azu_wit_create_work_item` — Create work item
- `mcp_microsoft_azu_core_list_projects` — List available projects
- `mcp_microsoft_azu_wit_get_work_item` — Validate work item creation

## Tags
`azure-devops`, `work-items`, `project-management`, `automation`, `ado`
