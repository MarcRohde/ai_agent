# Skill: WorkIQ User MCP

## Description
Use the Work IQ User MCP server (`mcp_MeServer`) to retrieve signed-in user profile context and identity-driven metadata needed by other M365 workflows.

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| `task` | Yes | User profile or identity context request |
| `preview_tool_count` | No | Number of tools to preview during discovery (default: 5) |
| `try_tool_call` | No | When `true`, perform a read-only tool invocation |

## Preconditions
1. `EXO_CLIENT_ID` and `EXO_TENANT_ID` are set.
2. `WORKIQ_USER_TOKEN` is set.
3. `.vscode/mcp.json` contains `workiq-user`.

## Steps

1. **Acquire token**
   - Run `tools/scripts/Set-WorkIQMcpToken.ps1` with:
     - `-Scope 'McpServers.Me.All'`
     - `-TokenEnvVar 'WORKIQ_USER_TOKEN'`
     - `-ServerAlias 'workiq-user'`

2. **Validate server and discover tools**
   - Run `tools/scripts/Test-WorkIQMcpServer.ps1` with endpoint:
     - `https://agent365.svc.cloud.microsoft/agents/servers/mcp_MeServer/`

3. **Execute the minimum required read operation**
   - Use the least-privilege tool path that answers `task`.

4. **Return normalized identity output**
   - Surface user identifiers, display details, and any constraints.

## Output

```markdown
## WorkIQ User MCP Result

- Server: `workiq-user`
- Scope: `McpServers.Me.All`
- Task: `{task}`
- Tool used: `{tool_name}`
- Status: `{success|failed}`

### Identity Context
{Profile and user-context fields returned by the server}
```

## Referenced Prompts
- `prompts/system/default_system.md`

## Referenced Tools
- `tools/scripts/Set-WorkIQMcpToken.ps1`
- `tools/scripts/Test-WorkIQMcpServer.ps1`

## Tags
`workiq`, `mcp`, `user-profile`, `microsoft-365`, `agent365`
