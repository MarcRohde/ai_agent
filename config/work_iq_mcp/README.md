# Work IQ MCP Rollout

This folder holds the planning and catalog files for Work IQ MCP servers.

The goal is to support multiple Work IQ endpoints over time without hardcoding Mail-specific assumptions into the workspace structure.

## Scope

This workspace maintains an all-server Work IQ baseline in VS Code.
Use `catalog.json` as the source of truth for aliases, scopes, endpoints, and token environment variables.

## Naming Conventions

Use these names consistently across documentation, VS Code config, and future generated manifests:

- `serverId`: the Microsoft-published MCP server identifier. Keep this value exactly as published, for example `mcp_MailTools`.
- `alias`: the local VS Code server label. Use lowercase kebab case in the form `workiq-<capability>`.
- `environment suffix`: only add a suffix when more than one tenant or environment must coexist, for example `workiq-mail-prod` or `workiq-mail-dev`.
- `catalog file`: keep shared metadata in `catalog.json` so future server additions do not require hunting through notes.

## All-Server Baseline

This workspace now enables all documented Work IQ servers in `.vscode/mcp.json`:

1. `workiq-mail`
2. `workiq-user`
3. `workiq-calendar`
4. `workiq-teams`
5. `workiq-word`
6. `workiq-copilot`

Each server keeps its Microsoft `serverId` and has a dedicated token environment variable.

## Expansion Workflow

When adding a new Work IQ server later:

1. Verify the server ID, scope, and documentation URL from Microsoft docs.
2. Add or update the server entry in `catalog.json`.
3. Update `.vscode/mcp.json` by running `tools/scripts/Sync-WorkIQMcpConfig.ps1`.
4. Acquire token(s) with `tools/scripts/Set-WorkIQAllTokens.ps1`.
5. Validate all enabled servers with `tools/scripts/Test-WorkIQAllMcp.ps1`.
6. If this workspace later becomes a full Agent 365 project, let the CLI generate `ToolingManifest.json` rather than hand-authoring one.

## Local Bootstrap

The workspace uses direct VS Code HTTP MCP entries plus bearer tokens stored in environment variables.

Use the one-command bootstrap flow on new machines:

1. Ensure Azure CLI is signed into the target tenant.
2. Reuse the shared M365 app registration by setting `EXO_TENANT_ID` and `EXO_CLIENT_ID`.
  - If you use `start-outlook-auth-server.ps1`, also set `EXO_CLIENT_SECRET`.
   - If you see `AADSTS500113: No reply address is registered for the application`, add these public-client redirect URIs on that app registration:
     - `http://localhost:8400/`
     - `ms-appx-web://Microsoft.AAD.BrokerPlugin/<client-id>`
3. Run `tools/scripts/Bootstrap-WorkIQEnvironment.ps1`.
4. Complete any first-run Windows Account Manager sign-in or consent prompts.
5. Reload VS Code MCP servers.

The bootstrap flow also writes compatibility aliases for the Outlook auth helper:

- `MS_CLIENT_ID` from `EXO_CLIENT_ID`
- `MS_TENANT_ID` from `EXO_TENANT_ID`
- `MS_CLIENT_SECRET` from `EXO_CLIENT_SECRET` when provided

Manual equivalents:

1. `tools/scripts/Sync-WorkIQMcpConfig.ps1`
2. `tools/scripts/Set-WorkIQAllTokens.ps1`
3. `tools/scripts/Test-WorkIQAllMcp.ps1 -SkipToolCall`

Server-specific helpers still available:

- `tools/scripts/Set-WorkIQMcpToken.ps1`
- `tools/scripts/Test-WorkIQMcpServer.ps1`
- `tools/scripts/Set-WorkIQMailToken.ps1`
- `tools/scripts/Test-WorkIQMailMcp.ps1`

## Current Mail Mutation Notes

- The observed WorkIQ Mail tool surface includes `DeleteMessage` and `GetMessage`, but `MoveMessage` may not be available.
- Requests to move a message to Deleted Items should not silently fall back to delete; require explicit confirmation if only `DeleteMessage` exists.
- Preserve `ItemID` values exactly as URL-encoded in OWA links or search citations.
- `DeleteMessage` can remove the message from store without making it discoverable in Deleted Items, so verify via `GetMessage` rather than assuming soft-delete behavior.

## Endpoint Pattern

For the currently documented Work IQ server pattern, use:

```text
https://agent365.svc.cloud.microsoft/agents/servers/<serverId>/
```

## Notes

- These servers are preview/Frontier features and should be treated as change-prone.
- Tenant permissions and admin approval are separate from local VS Code configuration.
- This folder documents expansion strategy; the current workspace does not depend on `a365.config.json` or `ToolingManifest.json` for the current Work IQ rollout.
