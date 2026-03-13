# Tools Directory

This directory contains helper scripts and tool definitions that skills can invoke.

## Structure

```
tools/
├── README.md
└── scripts/          # Executable scripts
    ├── AzureDevOps/
    │   └── Analyze-HelpDeskItems.py
    ├── M365/
    │   ├── Get-ArchiveMessages.ps1
    │   ├── Get-M365GraphAccessToken.ps1
    │   ├── Invoke-WorkIQMailAction.ps1
    │   └── Search-M365Knowledge.ps1
    ├── Bootstrap-DevEnvironment.ps1
    ├── Bootstrap-WorkIQEnvironment.ps1
    ├── New-ProjectBootstrap.ps1
    ├── Set-WorkIQAllTokens.ps1
    ├── Set-WorkIQMailToken.ps1
    ├── Set-WorkIQMcpToken.ps1
    ├── Sync-WorkIQMcpConfig.ps1
    ├── Test-WorkIQAllMcp.ps1
    ├── Test-WorkIQMailMcp.ps1
    ├── Test-WorkIQMcpServer.ps1
    ├── Validate-DevEnvironment.ps1
    └── lint_and_fix.ps1
```

## Conventions

- Scripts include a usage header comment.
- Scripts handle errors gracefully and provide clear output.
- Add new scripts here when a skill needs to automate a terminal operation.

## Notable Scripts

| Script | Purpose |
|--------|---------|
| `scripts/AzureDevOps/Analyze-HelpDeskItems.py` | Analyze Azure DevOps Help Desk work items by assignee, calculating average days open and identifying longest open items |
| `scripts/M365/Get-M365GraphAccessToken.ps1` | Resolve a Microsoft Graph token from env, Azure CLI, automatic browser `az login`, or device code flow |
| `scripts/M365/Search-M365Knowledge.ps1` | Query Microsoft Graph search for knowledge retrieval with citation-ready output and automatic Azure CLI browser sign-in fallback |
| `scripts/M365/Get-ArchiveMessages.ps1` | Retrieve the most recent Archive emails from Microsoft Graph using cached token context |
| `scripts/M365/Invoke-WorkIQMailAction.ps1` | Safe WorkIQ Mail wrapper for search/get/delete with explicit confirmation and verification |
| `scripts/Bootstrap-DevEnvironment.ps1` | General environment bootstrap with optional chained Work IQ MCP setup via `-BootstrapWorkIQ` |
| `scripts/Bootstrap-WorkIQEnvironment.ps1` | One-command bootstrap for Work IQ MCP setup on new machines |
| `scripts/Sync-WorkIQMcpConfig.ps1` | Sync `.vscode/mcp.json` Work IQ entries from `config/work_iq_mcp/catalog.json` |
| `scripts/Set-WorkIQAllTokens.ps1` | Acquire tokens for all enabled Work IQ MCP server scopes |
| `scripts/Test-WorkIQAllMcp.ps1` | Validate connectivity and tool discovery for all enabled Work IQ MCP servers |

## M365 and Exchange Grouping

- Microsoft 365 and Exchange-adjacent automation scripts in this repository are grouped under `tools/scripts/M365/`.
- Workspace operational Exchange EWS scripts remain in `work-projects/scripts/Exchange/` and can be consolidated here later if desired.
