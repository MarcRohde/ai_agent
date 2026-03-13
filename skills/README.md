# Skills Directory

This directory contains individual skill definitions. Each skill is organized in its own named subfolder with a standardized `skill.md` file.

## Folder Structure

```
skills/
├── andis_bi_sql_change/
│   └── skill.md
├── andis_bi_semantic_view_change/
│   └── skill.md
├── azure_devops_work_item/
│   └── skill.md
├── code_review/
│   └── skill.md
├── documentation/
│   └── skill.md
├── explain_code/
│   └── skill.md
├── generate_tests/
│   └── skill.md
├── git_operations/
│   └── skill.md
├── m365_graph_knowledge/
│   └── skill.md
├── oauth2_integration/
│   └── skill.md
├── powershell_best_practices/
│   └── skill.md
├── workiq_calendar_mcp/
│   └── skill.md
├── workiq_copilot_mcp/
│   └── skill.md
├── workiq_mail_mcp/
│   └── skill.md
├── workiq_mail_operations/
│   └── skill.md
├── workiq_teams_mcp/
│   └── skill.md
├── workiq_user_mcp/
│   └── skill.md
├── workiq_word_mcp/
│   └── skill.md
├── api_resilience/
│   └── skill.md
├── refactor/
│   └── skill.md
├── repository_configuration_scaffold/
│   └── skill.md
└── README.md
```

## Conventions

- One skill per folder
- Folder names: `snake_case` (e.g., `code_review/`)
- The skill definition is always named `skill.md` inside the folder
- Additional skill-specific assets (scripts, configs, examples) can live alongside `skill.md`
- Every skill follows the structure in `../templates/skill_template.md`
- Register new skills in `../skill_library.md`

## Available Skills

| Folder | Category | Description |
|--------|----------|-------------|
| `code_review/` | Code Quality | Structured code review |
| `refactor/` | Code Quality | Code refactoring |
| `generate_tests/` | Testing | Unit test generation |
| `explain_code/` | Explanation | Code explanation |
| `git_operations/` | Git & Workflow | Git workflows |
| `documentation/` | Documentation | Doc generation |
| `andis_bi_sql_change/` | Andis BI Data Engineering | BI-specific SQL change planning and execution |
| `andis_bi_semantic_view_change/` | Andis BI Data Engineering | BI semantic view updates with join/grain validation |
| `m365_graph_knowledge/` | Knowledge Retrieval | Microsoft 365 Graph search for synced and non-synced enterprise content |
| `oauth2_integration/` | API Integration | OAuth2 token acquisition and refresh patterns |
| `api_resilience/` | API Integration | Retry, backoff, and throttling-safe API execution |
| `powershell_best_practices/` | Scripting & Automation | Production-ready PowerShell patterns |
| `azure_devops_work_item/` | Project Management | Azure DevOps work item creation with intelligent project inference |
| `repository_configuration_scaffold/` | DevOps & Environment | Scaffold repository mission/context files and learning loops |
| `workiq_mail_operations/` | Work IQ MCP | Safe mailbox search/get/delete workflows with capability and verification checks |
| `workiq_mail_mcp/` | Work IQ MCP | Mail server operations and workflow guardrails |
| `workiq_user_mcp/` | Work IQ MCP | User profile server operations and identity context retrieval |
| `workiq_calendar_mcp/` | Work IQ MCP | Calendar server operations and scheduling workflows |
| `workiq_teams_mcp/` | Work IQ MCP | Teams server operations for collaboration workflows |
| `workiq_word_mcp/` | Work IQ MCP | Word server operations for document workflows |
| `workiq_copilot_mcp/` | Work IQ MCP | Copilot server operations for grounded M365 retrieval |
