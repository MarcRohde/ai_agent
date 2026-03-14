<#
.SYNOPSIS
    One-command recovery bootstrap for the ai_agent workspace.

.DESCRIPTION
    Validates key prerequisites on a fresh machine, performs Azure CLI sign-in if
    needed, ensures the Agent 365 CLI is available, and then runs the standard
    chained bootstrap flow.

.EXAMPLE
    .\Recover-AiAgentEnvironment.ps1 -ClientAppId '<client-app-id>' -TenantId '<tenant-id>'

.EXAMPLE
    .\Recover-AiAgentEnvironment.ps1

.NOTES
    This script wraps tools/scripts/Bootstrap-DevEnvironment.ps1 with
    -BootstrapWorkIQ and safe defaults for machine recovery.
#>

[CmdletBinding()]
param(
    [string]$ClientAppId = $env:EXO_CLIENT_ID,
    [string]$TenantId = $env:EXO_TENANT_ID,
    [string]$ClientSecret = $(if (-not [string]::IsNullOrWhiteSpace($env:EXO_CLIENT_SECRET)) { $env:EXO_CLIENT_SECRET } else { $env:MS_CLIENT_SECRET }),

    [ValidateSet('User', 'Machine')]
    [string]$PersistScope = 'User',

    [switch]$DoNotUpdateCurrentSession,
    [switch]$SkipToolInstall,
    [switch]$SkipValidation,
    [switch]$ContinueOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-IsAdmin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Read-RequiredValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CurrentValue,
        [Parameter(Mandatory = $true)]
        [string]$Prompt
    )

    if (-not [string]::IsNullOrWhiteSpace($CurrentValue)) {
        return $CurrentValue
    }

    $value = Read-Host -Prompt $Prompt
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "$Prompt is required."
    }

    return $value
}

function Ensure-AzureCliLoggedIn {
    param([string]$ExpectedTenantId)

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw @'
Azure CLI not found. Install it first:
  winget install --id Microsoft.AzureCLI --silent
Then re-run this recovery script.
'@
    }

    $accountText = az account show --output json 2>$null | Out-String
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'Azure CLI is not logged in. Launching az login...' -ForegroundColor Yellow
        $loginArgs = @('login')
        if (-not [string]::IsNullOrWhiteSpace($ExpectedTenantId)) {
            $loginArgs += @('--tenant', $ExpectedTenantId)
        }

        & az @loginArgs
        if ($LASTEXITCODE -ne 0) {
            throw 'Azure CLI login failed.'
        }

        $accountText = az account show --output json 2>$null | Out-String
        if ($LASTEXITCODE -ne 0) {
            throw 'Azure CLI login did not produce a usable account context.'
        }
    }

    try {
        $account = $accountText | ConvertFrom-Json
    }
    catch {
        throw "Unable to parse Azure CLI account output: $accountText"
    }

    $activeTenantId = [string]$account.tenantId

    if (-not [string]::IsNullOrWhiteSpace($ExpectedTenantId) -and
        -not [string]::IsNullOrWhiteSpace($activeTenantId) -and
        $ExpectedTenantId -ne $activeTenantId) {

        Write-Host "Azure CLI is logged into tenant $activeTenantId, switching to $ExpectedTenantId..." -ForegroundColor Yellow
        & az login --tenant $ExpectedTenantId
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to authenticate Azure CLI to tenant $ExpectedTenantId."
        }

        $activeTenantId = $ExpectedTenantId
    }

    return $activeTenantId
}

function Ensure-A365Cli {
    if (Get-Command a365 -ErrorAction SilentlyContinue) {
        return
    }

    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
        throw @'
a365 CLI is not installed and dotnet was not found.
Install .NET SDK first, then rerun this script.
'@
    }

    $dotnetToolsPath = Join-Path $HOME '.dotnet\tools'
    if ((Test-Path $dotnetToolsPath) -and ($env:Path -notlike "*$dotnetToolsPath*")) {
        $env:Path = "$dotnetToolsPath;$env:Path"
    }

    Write-Host 'Installing/Updating a365 CLI...' -ForegroundColor Yellow
    & dotnet tool update --global Microsoft.Agents.A365.DevTools.Cli
    if ($LASTEXITCODE -ne 0) {
        & dotnet tool install --global Microsoft.Agents.A365.DevTools.Cli
    }

    if ((Test-Path $dotnetToolsPath) -and ($env:Path -notlike "*$dotnetToolsPath*")) {
        $env:Path = "$dotnetToolsPath;$env:Path"
    }

    if (-not (Get-Command a365 -ErrorAction SilentlyContinue)) {
        throw @'
a365 CLI install completed but command is still not available.
Open a new terminal and rerun this script.
'@
    }
}

if ($PersistScope -eq 'Machine' -and -not (Test-IsAdmin)) {
    throw "Machine scope requires Administrator privileges. Re-run as admin or use '-PersistScope User'."
}

$repoRoot = $PSScriptRoot
$bootstrapScript = Join-Path $repoRoot 'tools\scripts\Bootstrap-DevEnvironment.ps1'
if (-not (Test-Path $bootstrapScript)) {
    throw "Bootstrap script not found: $bootstrapScript"
}

Write-Host ''
Write-Host 'AI Agent Recovery Bootstrap' -ForegroundColor Cyan
Write-Host ('=' * 40) -ForegroundColor Cyan

$ClientAppId = Read-RequiredValue -CurrentValue $ClientAppId -Prompt 'Enter Work IQ client app ID (EXO_CLIENT_ID)'

if ([string]::IsNullOrWhiteSpace($TenantId)) {
    $TenantId = Read-Host -Prompt 'Enter tenant ID (EXO_TENANT_ID) or press Enter to use current az tenant'
}

$activeTenant = Ensure-AzureCliLoggedIn -ExpectedTenantId $TenantId
if ([string]::IsNullOrWhiteSpace($TenantId)) {
    $TenantId = $activeTenant
}

Ensure-A365Cli

$variables = @{
    EXO_CLIENT_ID = $ClientAppId
}

if (-not [string]::IsNullOrWhiteSpace($TenantId)) {
    $variables['EXO_TENANT_ID'] = $TenantId
}

if (-not [string]::IsNullOrWhiteSpace($ClientSecret)) {
    $variables['EXO_CLIENT_SECRET'] = $ClientSecret
}

$bootstrapParams = @{
    Variables       = $variables
    PersistScope    = $PersistScope
    BootstrapWorkIQ = $true
}

if ($DoNotUpdateCurrentSession.IsPresent) {
    $bootstrapParams['DoNotUpdateCurrentSession'] = $true
}
if ($SkipToolInstall.IsPresent) {
    $bootstrapParams['SkipToolInstall'] = $true
}
if ($SkipValidation.IsPresent) {
    $bootstrapParams['SkipValidation'] = $true
}
if ($ContinueOnError.IsPresent) {
    $bootstrapParams['ContinueOnError'] = $true
}

Write-Host "Client app ID: $ClientAppId" -ForegroundColor Gray
Write-Host "Tenant ID: $TenantId" -ForegroundColor Gray
Write-Host "Persist scope: $PersistScope" -ForegroundColor Gray
Write-Host ''

& $bootstrapScript @bootstrapParams
exit $LASTEXITCODE
