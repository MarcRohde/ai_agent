# Set-WorkIQMcpToken.ps1
# Retrieves a Work IQ MCP bearer token via the Agent 365 CLI and stores it in a
# user environment variable for VS Code MCP HTTP server configuration.
#
# Usage:
#   .\Set-WorkIQMcpToken.ps1 -Scope 'McpServers.Mail.All' -TokenEnvVar 'WORKIQ_MAIL_TOKEN'
#   .\Set-WorkIQMcpToken.ps1 -Scope 'McpServers.Calendar.All' -TokenEnvVar 'WORKIQ_CALENDAR_TOKEN'
#
# Defaults reuse the shared Exchange/M365 environment variables already used in
# this workspace (`EXO_CLIENT_ID` and `EXO_TENANT_ID`).

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Scope,

    [Parameter(Mandatory = $true)]
    [string]$TokenEnvVar,

    [string]$ServerAlias = 'workiq-server',
    [string]$ClientAppId = $env:EXO_CLIENT_ID,
    [string]$TenantId = $env:EXO_TENANT_ID,
    [switch]$Refresh
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-StringEmpty {
    param([string]$Value)
    return [string]::IsNullOrWhiteSpace($Value)
}

function Get-JwtFromText {
    param([string]$Text)

    if (Test-StringEmpty $Text) {
        return $null
    }

    # Match JWT-like tokens anywhere in output because some a365 versions emit
    # additional text around the token and may wrap lines.
    $jwtMatches = [regex]::Matches($Text, '[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+')
    if ($jwtMatches.Count -eq 0) {
        return $null
    }

    $jwtCandidates = @($jwtMatches | ForEach-Object { $_.Value.Trim() } | Where-Object { $_.Length -ge 100 })
    if ($jwtCandidates.Count -eq 0) {
        return $null
    }

    # Prefer the longest candidate to avoid partial fragments from wrapped output.
    return ($jwtCandidates | Sort-Object Length -Descending | Select-Object -First 1)
}

function ConvertTo-RedactedText {
    param([string]$Text)

    if (Test-StringEmpty $Text) {
        return $Text
    }

    return [regex]::Replace($Text, '[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+', '[REDACTED_JWT]')
}

Write-Host ''
Write-Host "Work IQ MCP Token Setup ($ServerAlias)" -ForegroundColor Cyan
Write-Host '--------------------------------' -ForegroundColor Cyan

if (-not (Get-Command a365 -ErrorAction SilentlyContinue)) {
    Write-Error 'a365 CLI not found. Install via: dotnet tool install -g Microsoft.Agents.A365.DevTools.Cli'
    exit 1
}

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error @'
Azure CLI not found. Install it first:
  winget install --id Microsoft.AzureCLI --silent
Then restart this terminal and run:
  az login
'@
    exit 1
}

$loginHint = if (Test-StringEmpty $TenantId) { 'az login' } else { "az login --tenant $TenantId" }
$azAccountText = az account show --output json 2>&1 | Out-String
if ($LASTEXITCODE -ne 0) {
    Write-Error "Azure CLI is not logged in. Run: $loginHint"
    exit 1
}

try {
    $azAccount = $azAccountText | ConvertFrom-Json
}
catch {
    Write-Error "Failed to parse Azure CLI account context.`n$azAccountText"
    exit 1
}

$activeTenantId = [string]$azAccount.tenantId
if (Test-StringEmpty $TenantId) {
    $TenantId = $activeTenantId
}

if (-not (Test-StringEmpty $TenantId) -and -not (Test-StringEmpty $activeTenantId) -and $TenantId -ne $activeTenantId) {
    Write-Error "Azure CLI is logged into tenant $activeTenantId, but $ServerAlias expects tenant $TenantId. Run: az login --tenant $TenantId"
    exit 1
}

if (Test-StringEmpty $ClientAppId) {
    Write-Error @'
Client app ID is required.
Set EXO_CLIENT_ID in your user environment, or pass:
  .\tools\scripts\Set-WorkIQMcpToken.ps1 -Scope "<scope>" -TokenEnvVar "<env-var>" -ClientAppId "<app-id>"
'@
    exit 1
}

Write-Host 'Azure CLI: authenticated' -ForegroundColor Green
Write-Host "Azure tenant: $TenantId" -ForegroundColor Gray
Write-Host "Client application: $ClientAppId" -ForegroundColor Gray
Write-Host "Scope: $Scope" -ForegroundColor Gray
Write-Host ''
Write-Host 'The first successful run may open a Windows Account Manager sign-in or consent dialog.' -ForegroundColor Yellow

$getTokenArgs = @(
    'develop',
    'get-token',
    '--app-id', $ClientAppId,
    '--scopes', $Scope,
    '--output', 'raw'
)

if ($Refresh) {
    $getTokenArgs += '--force-refresh'
}

Write-Host "Requesting token for $ServerAlias ..." -ForegroundColor Yellow
$commandOutput = (& a365 @getTokenArgs 2>&1 | Out-String)
$token = Get-JwtFromText -Text $commandOutput

if (Test-StringEmpty $token) {
    $message = "a365 develop get-token did not return a bearer token for $ServerAlias."
    if ($commandOutput -match 'Windows Account Manager|grant consent|sign in') {
        $message += "`nComplete the interactive sign-in or consent dialog, then rerun this script."
    }
    $safeOutput = ConvertTo-RedactedText -Text $commandOutput
    Write-Error "$message`n$safeOutput"
    exit 1
}

if ($LASTEXITCODE -ne 0) {
    Write-Warning "a365 returned exit code $LASTEXITCODE but a token was found; continuing."
}

[Environment]::SetEnvironmentVariable($TokenEnvVar, $token, 'User')
Set-Item -Path "Env:$TokenEnvVar" -Value $token

Write-Host ''
Write-Host "Token set in user environment variable: $TokenEnvVar" -ForegroundColor Green
Write-Host "Token length: $($token.Length) characters" -ForegroundColor Gray
Write-Host ''
Write-Host 'Next step: Restart VS Code or reload the MCP server so the new token is picked up.' -ForegroundColor Yellow
Write-Host "  VS Code command palette: MCP: Restart Server -> $ServerAlias" -ForegroundColor Gray
Write-Host ''
