# Start Outlook MCP Authentication Server using the current environment.
# Run this in a separate PowerShell window.

[CmdletBinding()]
param(
    [string]$AuthServerPath = (Join-Path $env:APPDATA 'npm\node_modules\outlook-mcp'),
    [switch]$PreviewOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-EnvironmentValue {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Names
    )

    foreach ($name in $Names) {
        foreach ($scope in 'Process', 'User', 'Machine') {
            $value = [Environment]::GetEnvironmentVariable($name, $scope)
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                return [pscustomobject]@{
                    Name  = $name
                    Scope = $scope
                    Value = $value
                }
            }
        }
    }

    return $null
}

$clientId = Get-EnvironmentValue -Names @('MS_CLIENT_ID', 'EXO_CLIENT_ID')
$clientSecret = Get-EnvironmentValue -Names @('MS_CLIENT_SECRET', 'EXO_CLIENT_SECRET')
$tenantId = Get-EnvironmentValue -Names @('MS_TENANT_ID', 'EXO_TENANT_ID')

$missing = @()
if ($null -eq $clientId) {
    $missing += 'MS_CLIENT_ID or EXO_CLIENT_ID'
}
if ($null -eq $clientSecret) {
    $missing += 'MS_CLIENT_SECRET or EXO_CLIENT_SECRET'
}
if ($null -eq $tenantId) {
    $missing += 'MS_TENANT_ID or EXO_TENANT_ID'
}

if ($missing.Count -gt 0) {
    throw @"
Missing required environment variables for the Outlook auth server:
 - $($missing -join "`n - ")

Set the EXO_* variables through the bootstrap flow, or set the MS_* variables directly.
Example:
  .\tools\scripts\Bootstrap-DevEnvironment.ps1 -Variables @{
	  EXO_CLIENT_ID = '<client-app-id>'
	  EXO_TENANT_ID = '<tenant-id>'
	  EXO_CLIENT_SECRET = '<client-secret>'
  } -BootstrapWorkIQ
"@
}

$env:MS_CLIENT_ID = $clientId.Value
$env:MS_CLIENT_SECRET = $clientSecret.Value
$env:MS_TENANT_ID = $tenantId.Value

$authServerScript = Join-Path $AuthServerPath 'outlook-auth-server.js'
if (-not (Test-Path $authServerScript)) {
    throw "Outlook auth server script not found: $authServerScript"
}

Write-Host ''
Write-Host '╔════════════════════════════════════════════════════════════════╗' -ForegroundColor Cyan
Write-Host '║          Outlook MCP Authentication Server Starting           ║' -ForegroundColor Cyan
Write-Host '╚════════════════════════════════════════════════════════════════╝' -ForegroundColor Cyan
Write-Host ''
Write-Host '✓ Environment variables resolved for this session' -ForegroundColor Green
Write-Host "  Client ID: $($clientId.Value) [$($clientId.Name) / $($clientId.Scope)]" -ForegroundColor Gray
Write-Host "  Tenant ID: $($tenantId.Value) [$($tenantId.Name) / $($tenantId.Scope)]" -ForegroundColor Gray
Write-Host "  Client Secret: loaded from $($clientSecret.Name) [$($clientSecret.Scope)]" -ForegroundColor Gray
Write-Host "  Auth Server Path: $AuthServerPath" -ForegroundColor Gray
Write-Host ''
Write-Host '🌐 Authentication URL:' -ForegroundColor Yellow
Write-Host '   http://localhost:3333/auth' -ForegroundColor Cyan
Write-Host ''
Write-Host '📋 Instructions:' -ForegroundColor Yellow
Write-Host '   1. Refresh your browser at http://localhost:3333/auth' -ForegroundColor White
Write-Host '   2. Sign in with your Microsoft account' -ForegroundColor White
Write-Host '   3. Grant the requested permissions' -ForegroundColor White
Write-Host '   4. Leave this window open (Press Ctrl+C to stop)' -ForegroundColor White
Write-Host ''
Write-Host '════════════════════════════════════════════════════════════════' -ForegroundColor Cyan
Write-Host ''

if ($PreviewOnly.IsPresent) {
    Write-Host 'PreviewOnly set. Environment resolved successfully; auth server not started.' -ForegroundColor Yellow
    exit 0
}

Set-Location $AuthServerPath
node outlook-auth-server.js
