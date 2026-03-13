# Skill Library — Master Index

> This file is the registry of all available skills. AI agents should read this file to discover what skills are available.

## How to Use

Search this index by **category** or **skill name** to find the right skill, then read the linked skill file for full instructions.

> **Precedence Note:** This library is the **general-purpose default**. If another open workspace folder (e.g., a project repo or team library) defines a skill with the **same name**, that version takes priority. Project-specific skills always override this library, and other open libraries override it as well. See `AI Agents Overview.md § Skill Resolution & Precedence` for the full rules.

---

## Skills

### Code Quality

| Skill | File | Description |
|-------|------|-------------|
| Code Review | [skills/code_review/skill.md](skills/code_review/skill.md) | Perform a structured code review with actionable feedback |
| Refactor | [skills/refactor/skill.md](skills/refactor/skill.md) | Refactor code for readability, performance, or pattern compliance |

### Testing

| Skill | File | Description |
|-------|------|-------------|
| Generate Tests | [skills/generate_tests/skill.md](skills/generate_tests/skill.md) | Generate unit tests for a given file or function |

### Documentation

| Skill | File | Description |
|-------|------|-------------|
| Documentation | [skills/documentation/skill.md](skills/documentation/skill.md) | Generate or update documentation for code, APIs, or projects |

### Explanation

| Skill | File | Description |
|-------|------|-------------|
| Explain Code | [skills/explain_code/skill.md](skills/explain_code/skill.md) | Explain what a piece of code does, its patterns, and trade-offs |

### Git & Workflow

| Skill | File | Description |
|-------|------|-------------|
| Git Operations | [skills/git_operations/skill.md](skills/git_operations/skill.md) | Common git workflows: branching, commits, PR descriptions |

### API Integration

| Skill | File | Description |
|-------|------|-------------|
| OAuth2 Integration | [skills/oauth2_integration/skill.md](skills/oauth2_integration/skill.md) | Implement OAuth2 authentication flows with token management and refresh |
| API Resilience & Throttling | [skills/api_resilience/skill.md](skills/api_resilience/skill.md) | Build robust API calls with retry logic, backoff, and rate limit handling |

### Knowledge Retrieval

| Skill | File | Description |
|-------|------|-------------|
| M365 Graph Knowledge | [skills/m365_graph_knowledge/skill.md](skills/m365_graph_knowledge/skill.md) | Retrieve grounded answers from Microsoft 365 (including non-synced SharePoint/OneDrive content) using Graph search and connector-backed external items |

### Scripting & Automation

| Skill | File | Description |
|-------|------|-------------|
| PowerShell Best Practices | [skills/powershell_best_practices/skill.md](skills/powershell_best_practices/skill.md) | Develop production-quality PowerShell scripts with proper error handling and documentation |

### DevOps & Environment

| Skill | File | Description |
|-------|------|-------------|
| Dev Environment Bootstrap | [skills/dev_environment_bootstrap/skill.md](skills/dev_environment_bootstrap/skill.md) | Create portable bootstrap scripts for consistent development environment setup |
| Repository Configuration Scaffold | [skills/repository_configuration_scaffold/skill.md](skills/repository_configuration_scaffold/skill.md) | Configure mission/context scaffolding and committed learning loops for new or existing repositories |

### Project Management

| Skill | File | Description |
|-------|------|-------------|
| Azure DevOps Work Item Creation | [skills/azure_devops_work_item/skill.md](skills/azure_devops_work_item/skill.md) | Create Azure DevOps work items with intelligent project inference, comprehensive descriptions, and attachment handling |

### Work IQ MCP

| Skill | File | Description |
|-------|------|-------------|
| WorkIQ Mail Operations | [skills/workiq_mail_operations/skill.md](skills/workiq_mail_operations/skill.md) | Search, inspect, and delete mail with capability discovery, fallback gates, and verification |
| WorkIQ Mail MCP | [skills/workiq_mail_mcp/skill.md](skills/workiq_mail_mcp/skill.md) | Use Work IQ Mail MCP for mailbox read/write workflows with safety guardrails |
| WorkIQ User MCP | [skills/workiq_user_mcp/skill.md](skills/workiq_user_mcp/skill.md) | Use Work IQ User MCP for identity and user context retrieval |
| WorkIQ Calendar MCP | [skills/workiq_calendar_mcp/skill.md](skills/workiq_calendar_mcp/skill.md) | Use Work IQ Calendar MCP for scheduling and event workflows |
| WorkIQ Teams MCP | [skills/workiq_teams_mcp/skill.md](skills/workiq_teams_mcp/skill.md) | Use Work IQ Teams MCP for collaboration and Teams operations |
| WorkIQ Word MCP | [skills/workiq_word_mcp/skill.md](skills/workiq_word_mcp/skill.md) | Use Work IQ Word MCP for document-oriented workflows |
| WorkIQ Copilot MCP | [skills/workiq_copilot_mcp/skill.md](skills/workiq_copilot_mcp/skill.md) | Use Work IQ Copilot MCP for grounded M365 Copilot-style operations |

### Andis BI Data Engineering

| Skill | File | Description |
|-------|------|-------------|
| Andis BI SQL Change | [skills/andis_bi_sql_change/skill.md](skills/andis_bi_sql_change/skill.md) | Plan and execute SQL changes for Andis BI environments with guardrails, validation, and rollback |
| Andis BI Semantic View Change | [skills/andis_bi_semantic_view_change/skill.md](skills/andis_bi_semantic_view_change/skill.md) | Update `ods.dim*` views with join determinism checks, grain protection, and semantic validation |

---

## Adding a New Skill

1. Create a new folder in `skills/` named after the skill (e.g., `skills/my_skill/`).
2. Add a `skill.md` file inside the folder using `templates/skill_template.md`.
3. Add a row to the appropriate category table above.
4. If a new category is needed, add a new `###` section.
