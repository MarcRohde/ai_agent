# Skill: WorkIQ Copilot MCP

## Description
Use the Work IQ Copilot MCP server (`mcp_M365Copilot`) for grounded Microsoft 365 Copilot-style retrieval and orchestration tasks, with clear citations and transparent scope boundaries.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `task` | Yes | Copilot retrieval/orchestration task |
| `mode` | No | `read-only` (default) or `mutating` |
| `preview_tool_count` | No | Number of tools to preview during discovery (default: 5) |

## Preconditions
1. `EXO_CLIENT_ID` and `EXO_TENANT_ID` are set.
2. `WORKIQ_COPILOT_TOKEN` is set.
3. `.vscode/mcp.json` contains `workiq-copilot`.

## Steps

1. **Acquire token**
   - Run `tools/scripts/Set-WorkIQMcpToken.ps1` with:
     - `-Scope 'McpServers.CopilotMCP.All'`
     - `-TokenEnvVar 'WORKIQ_COPILOT_TOKEN'`
     - `-ServerAlias 'workiq-copilot'`

2. **Validate server and discover tools**
   - Run `tools/scripts/Test-WorkIQMcpServer.ps1` with endpoint:
     - `https://agent365.svc.cloud.microsoft/agents/servers/mcp_M365Copilot/`

3. **Run scoped Copilot operation**
   - Start with read-only retrieval and synthesis.
   - Confirm before any mutating workflow.

4. **Return grounded response**
   - Include key findings, source references, and limitations.

## Output

```markdown
## WorkIQ Copilot MCP Result

- Server: `workiq-copilot`
- Scope: `McpServers.CopilotMCP.All`
- Task: `{task}`
- Tool used: `{tool_name}`
- Mode: `{read-only|mutating}`
- Status: `{success|failed}`

### Grounded Output
{Response with references and caveats}
```

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- `tools/scripts/Set-WorkIQMcpToken.ps1`
- `tools/scripts/Test-WorkIQMcpServer.ps1`

## Tags
`workiq`, `mcp`, `copilot`, `microsoft-365`, `knowledge`, `agent365`
