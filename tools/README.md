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
    │   └── Search-M365Knowledge.ps1
    ├── Bootstrap-DevEnvironment.ps1
    ├── New-ProjectBootstrap.ps1
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

## M365 and Exchange Grouping

- Microsoft 365 and Exchange-adjacent automation scripts in this repository are grouped under `tools/scripts/M365/`.
- Workspace operational Exchange EWS scripts remain in `work-projects/scripts/Exchange/` and can be consolidated here later if desired.
