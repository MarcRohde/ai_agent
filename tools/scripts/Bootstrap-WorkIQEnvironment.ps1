# Bootstrap-WorkIQEnvironment.ps1
# One-command bootstrap for Work IQ MCP servers on a new machine.

[CmdletBinding()]
param(
    [string]$ClientAppId = $env:EXO_CLIENT_ID,
    [string]$ClientSecret = $(if (-not [string]::IsNullOrWhiteSpace($env:EXO_CLIENT_SECRET)) { $env:EXO_CLIENT_SECRET } else { $env:MS_CLIENT_SECRET }),
    [string]$TenantId = $env:EXO_TENANT_ID,
    [ValidateSet('User', 'Machine')]
    [string]$PersistScope = 'User',
    [switch]$DoNotUpdateCurrentSession,
    [switch]$RefreshTokens,
    [switch]$SkipTokenSetup,
    [switch]$SkipValidation,
    [switch]$ContinueOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Set-EnvironmentVariableValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value,
        [Parameter(Mandatory = $true)]
        [ValidateSet('User', 'Machine')]
        [string]$Scope,
        [Parameter(Mandatory = $true)]
        [bool]$UpdateSession
    )

    [Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
    if ($UpdateSession) {
        Set-Item -Path "Env:$Name" -Value $Value -Force
    }
}

function Test-IsAdmin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$syncScript = Join-Path $PSScriptRoot 'Sync-WorkIQMcpConfig.ps1'
$tokenScript = Join-Path $PSScriptRoot 'Set-WorkIQAllTokens.ps1'
$testScript = Join-Path $PSScriptRoot 'Test-WorkIQAllMcp.ps1'
$catalogPath = Join-Path $repoRoot 'config\work_iq_mcp\catalog.json'

if ($PersistScope -eq 'Machine' -and -not (Test-IsAdmin)) {
    throw "Machine scope requires Administrator privileges. Re-run as admin or use '-PersistScope User'."
}

if ([string]::IsNullOrWhiteSpace($ClientAppId)) {
    throw "Client app ID is required. Pass -ClientAppId or set EXO_CLIENT_ID."
}

if ([string]::IsNullOrWhiteSpace($TenantId)) {
    Write-Warning 'Tenant ID is not set. Token setup may fail if Azure CLI is authenticated to a different tenant.'
}

Write-Host ''
Write-Host 'Work IQ Environment Bootstrap' -ForegroundColor Cyan
Write-Host ('=' * 40) -ForegroundColor Cyan
Write-Host "Repo root: $repoRoot" -ForegroundColor Gray
Write-Host "Persist scope: $PersistScope" -ForegroundColor Gray

$updateSession = -not $DoNotUpdateCurrentSession.IsPresent
Set-EnvironmentVariableValue -Name 'EXO_CLIENT_ID' -Value $ClientAppId -Scope $PersistScope -UpdateSession $updateSession
Set-EnvironmentVariableValue -Name 'MS_CLIENT_ID' -Value $ClientAppId -Scope $PersistScope -UpdateSession $updateSession
if (-not [string]::IsNullOrWhiteSpace($TenantId)) {
    Set-EnvironmentVariableValue -Name 'EXO_TENANT_ID' -Value $TenantId -Scope $PersistScope -UpdateSession $updateSession
    Set-EnvironmentVariableValue -Name 'MS_TENANT_ID' -Value $TenantId -Scope $PersistScope -UpdateSession $updateSession
}

if (-not [string]::IsNullOrWhiteSpace($ClientSecret)) {
    Set-EnvironmentVariableValue -Name 'EXO_CLIENT_SECRET' -Value $ClientSecret -Scope $PersistScope -UpdateSession $updateSession
    Set-EnvironmentVariableValue -Name 'MS_CLIENT_SECRET' -Value $ClientSecret -Scope $PersistScope -UpdateSession $updateSession
}

Write-Host 'Set base environment variables: EXO_CLIENT_ID / MS_CLIENT_ID and EXO_TENANT_ID / MS_TENANT_ID' -ForegroundColor Green
if (-not [string]::IsNullOrWhiteSpace($ClientSecret)) {
    Write-Host 'Set compatibility client secret variables: EXO_CLIENT_SECRET / MS_CLIENT_SECRET' -ForegroundColor Green
}
else {
    Write-Warning 'Client secret not set. If you use start-outlook-auth-server.ps1, set EXO_CLIENT_SECRET or MS_CLIENT_SECRET first.'
}

if (-not (Test-Path $syncScript)) {
    throw "Required script not found: $syncScript"
}

& $syncScript -CatalogPath $catalogPath

if (-not $SkipTokenSetup.IsPresent) {
    if (-not (Test-Path $tokenScript)) {
        throw "Required script not found: $tokenScript"
    }

    & $tokenScript `
        -CatalogPath $catalogPath `
        -ClientAppId $ClientAppId `
        -TenantId $TenantId `
        -Refresh:$RefreshTokens.IsPresent `
        -ContinueOnError:$ContinueOnError.IsPresent
}
else {
    Write-Warning 'Skipping token setup (-SkipTokenSetup).'
}

if (-not $SkipValidation.IsPresent) {
    if (-not (Test-Path $testScript)) {
        throw "Required script not found: $testScript"
    }

    & $testScript `
        -CatalogPath $catalogPath `
        -SkipToolCall `
        -ContinueOnError:$ContinueOnError.IsPresent
}
else {
    Write-Warning 'Skipping MCP validation (-SkipValidation).'
}

Write-Host ''
Write-Host 'Bootstrap complete.' -ForegroundColor Green
Write-Host 'Reload VS Code MCP servers to pick up updated configuration and tokens.' -ForegroundColor Yellow
