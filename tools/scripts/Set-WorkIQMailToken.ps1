# Set-WorkIQMailToken.ps1
# Mail-specific wrapper around the generic Work IQ MCP token helper.

[CmdletBinding()]
param(
    [string]$ClientAppId = $env:EXO_CLIENT_ID,
    [string]$TenantId = $env:EXO_TENANT_ID,
    [switch]$Refresh
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

& "$PSScriptRoot\Set-WorkIQMcpToken.ps1" `
    -Scope 'McpServers.Mail.All' `
    -TokenEnvVar 'WORKIQ_MAIL_TOKEN' `
    -ServerAlias 'workiq-mail' `
    -ClientAppId $ClientAppId `
    -TenantId $TenantId `
    -Refresh:$Refresh.IsPresent
