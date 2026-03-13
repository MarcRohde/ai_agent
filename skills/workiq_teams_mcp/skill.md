# Skill: WorkIQ Teams MCP

## Description
Use the Work IQ Teams MCP server (`mcp_TeamsServer`) for Microsoft Teams conversation and collaboration workflows, with explicit confirmation before any operation that posts, updates, or removes content.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `task` | Yes | Teams collaboration request |
| `mode` | No | `read-only` (default) or `mutating` |
| `preview_tool_count` | No | Number of tools to preview during discovery (default: 5) |

## Preconditions
1. `EXO_CLIENT_ID` and `EXO_TENANT_ID` are set.
2. `WORKIQ_TEAMS_TOKEN` is set.
3. `.vscode/mcp.json` contains `workiq-teams`.

## Steps

1. **Acquire token**
   - Run `tools/scripts/Set-WorkIQMcpToken.ps1` with:
     - `-Scope 'McpServers.Teams.All'`
     - `-TokenEnvVar 'WORKIQ_TEAMS_TOKEN'`
     - `-ServerAlias 'workiq-teams'`

2. **Validate server and discover tools**
   - Run `tools/scripts/Test-WorkIQMcpServer.ps1` with endpoint:
     - `https://agent365.svc.cloud.microsoft/agents/servers/mcp_TeamsServer/`

3. **Execute requested action**
   - Use read-only tools by default.
   - Confirm before mutating message or channel content.

4. **Return collaboration summary**
   - Include channel/chat context, participants, and operation outcome.

## Output

```markdown
## WorkIQ Teams MCP Result

- Server: `workiq-teams`
- Scope: `McpServers.Teams.All`
- Task: `{task}`
- Tool used: `{tool_name}`
- Mode: `{read-only|mutating}`
- Status: `{success|failed}`

### Teams Context
{Conversation details and results}
```

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- `tools/scripts/Set-WorkIQMcpToken.ps1`
- `tools/scripts/Test-WorkIQMcpServer.ps1`

## Tags
`workiq`, `mcp`, `teams`, `collaboration`, `microsoft-365`, `agent365`
