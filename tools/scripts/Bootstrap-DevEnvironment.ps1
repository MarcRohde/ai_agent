<#
.SYNOPSIS
    Bootstrap a development environment with environment variables and validation.

.DESCRIPTION
    Sets user or machine-level environment variables for development projects.
    Validates prerequisites, handles admin requirements for Machine scope,
    and provides immediate session variable updates.

.PARAMETER Variables
    Hashtable of environment variables to set. Format: @{VAR_NAME='value'}

.PARAMETER PersistScope
    Environment variable scope: User (default) or Machine (requires admin).

.PARAMETER UpdateCurrentSession
    Update current PowerShell session variables immediately (default: true).

.PARAMETER Validate
    Validate environment after setting variables (default: true).

.PARAMETER SkipToolInstall
    Skip automatic installation of MCP tools (e.g., @playwright/mcp).

.PARAMETER BootstrapWorkIQ
    After setting base environment variables, run the Work IQ MCP bootstrap flow.

.PARAMETER ContinueOnError
    Continue through optional Work IQ bootstrap failures and surface warnings instead of stopping immediately.

.EXAMPLE
    .\Bootstrap-DevEnvironment.ps1 -Variables @{
        TENANT_ID='7d2c093d-4c2f-41e8-b222-0039fd152112'
        CLIENT_ID='a27799c8-18f2-4b9a-bdb7-ea913b465d70'
    }

.EXAMPLE
    .\Bootstrap-DevEnvironment.ps1 -Variables @{API_KEY='secret'} -PersistScope Machine

.EXAMPLE
    .\Bootstrap-DevEnvironment.ps1 -Variables @{
        EXO_CLIENT_ID='71c9fb1e-949c-45f0-9e01-f2ffbb1fc1fe'
        EXO_TENANT_ID='7d2c093d-4c2f-41e8-b222-0039fd152112'
        EXO_CLIENT_SECRET='<optional-outlook-auth-server-secret>'
    } -BootstrapWorkIQ

.NOTES
    Author: AI Agent
    Date: 2026-03-02
    Purpose: Standardized dev environment setup across projects
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [hashtable]$Variables,

    [Parameter(Mandatory = $false)]
    [ValidateSet('User', 'Machine')]
    [string]$PersistScope = 'User',

    [Parameter(Mandatory = $false)]
    [switch]$DoNotUpdateCurrentSession,

    [Parameter(Mandatory = $false)]
    [switch]$SkipValidation,

    [Parameter(Mandatory = $false)]
    [switch]$SkipToolInstall,

    [Parameter(Mandatory = $false)]
    [switch]$BootstrapWorkIQ,

    [Parameter(Mandatory = $false)]
    [switch]$ContinueOnError
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Set-EnvironmentVariable {
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

    try {
        [Environment]::SetEnvironmentVariable($Name, $Value, $Scope)

        if ($UpdateSession) {
            Set-Item -Path "Env:$Name" -Value $Value -Force
        }

        return $true
    }
    catch {
        Write-Error "Failed to set $Name : $_"
        return $false
    }
}

function Install-PlaywrightMcp {
    Write-Host "`nChecking Playwright MCP..." -ForegroundColor Cyan

    # Verify npm is available
    if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Host "  npm not found. Skipping Playwright MCP install (install Node.js to enable)." -ForegroundColor Yellow
        return
    }

    # Check if @playwright/mcp is already installed globally
    $installed = npm list -g --depth=0 2>$null | Select-String '@playwright/mcp'
    if ($installed) {
        Write-Host "  @playwright/mcp already installed." -ForegroundColor Green
        return
    }

    Write-Host "  Installing @playwright/mcp globally..." -NoNewline
    try {
        npm install -g @playwright/mcp 2>&1 | Out-Null
        Write-Host " OK" -ForegroundColor Green
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Warning "Could not install @playwright/mcp: $_"
    }
}

function Get-VariableValue {
    param(
        [hashtable]$Map,
        [string]$Name,
        [string]$Fallback
    )

    if ($null -ne $Map -and $Map.ContainsKey($Name)) {
        return [string]$Map[$Name]
    }

    return $Fallback
}

# Pre-flight checks
Write-Host "Dev Environment Bootstrap" -ForegroundColor Cyan
Write-Host ("=" * 50)

if ($PersistScope -eq 'Machine' -and -not (Test-IsAdmin)) {
    Write-Error "Machine scope requires Administrator privileges. Re-run PowerShell as Administrator or use '-PersistScope User'."
    exit 1
}

# Install required MCP tools
if (-not $SkipToolInstall) {
    Install-PlaywrightMcp
}

$updateSession = -not $DoNotUpdateCurrentSession.IsPresent
$successCount = 0
$failureCount = 0
$results = @()
$workIqBootstrapFailed = $false

if ($Variables.Count -gt 0) {
    Write-Host "`nSetting $($Variables.Count) environment variable(s) at $PersistScope scope..." -ForegroundColor White

    foreach ($entry in $Variables.GetEnumerator()) {
        $name = $entry.Key
        $value = $entry.Value

        Write-Host "  Setting $name..." -NoNewline

        $success = Set-EnvironmentVariable -Name $name -Value $value -Scope $PersistScope -UpdateSession $updateSession

        if ($success) {
            Write-Host " OK" -ForegroundColor Green
            $successCount++
            $results += [PSCustomObject]@{
                Variable = $name
                Status   = 'Set'
                Scope    = $PersistScope
                Value    = if ($name -match 'SECRET|PASSWORD|KEY|TOKEN') { '***' } else { $value }
            }
        }
        else {
            Write-Host " FAILED" -ForegroundColor Red
            $failureCount++
            $results += [PSCustomObject]@{
                Variable = $name
                Status   = 'Failed'
                Scope    = $PersistScope
                Value    = ''
            }
        }
    }

    # Summary
    Write-Host "`n" + ("=" * 50)
    Write-Host "Summary:" -ForegroundColor Cyan
    Write-Host "  Success: $successCount" -ForegroundColor Green
    Write-Host "  Failed : $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { 'Red' } else { 'Gray' })
    Write-Host "  Scope  : $PersistScope"

    if ($updateSession) {
        Write-Host "  Session: Updated" -ForegroundColor Green
    }
    else {
        Write-Host "  Session: Not updated (restart terminal to see changes)" -ForegroundColor Yellow
    }

    # Display results table
    Write-Host "`nVariables Set:" -ForegroundColor White
    $results | Format-Table -AutoSize

    # Validation
    if (-not $SkipValidation -and $successCount -gt 0) {
        Write-Host "`nValidating environment..." -ForegroundColor Cyan

        $validationScript = Join-Path $PSScriptRoot "Validate-DevEnvironment.ps1"
        if (Test-Path $validationScript) {
            $varNames = $Variables.Keys | ForEach-Object { $_ }
            & $validationScript -RequiredVariables $varNames -Quiet:$false
        }
        else {
            Write-Host "  Validation script not found. Skipping validation." -ForegroundColor Yellow
        }
    }
}
elseif (-not $BootstrapWorkIQ.IsPresent) {
    Write-Warning "No variables provided. Nothing to do."
    exit 0
}
else {
    Write-Host "`nNo base variables provided. Proceeding directly to optional Work IQ bootstrap." -ForegroundColor Yellow
}

if ($BootstrapWorkIQ.IsPresent) {
    $workIqBootstrapScript = Join-Path $PSScriptRoot 'Bootstrap-WorkIQEnvironment.ps1'
    if (-not (Test-Path $workIqBootstrapScript)) {
        $message = "Work IQ bootstrap script not found: $workIqBootstrapScript"
        if ($ContinueOnError.IsPresent) {
            Write-Warning $message
            $workIqBootstrapFailed = $true
        }
        else {
            throw $message
        }
    }
    else {
        $clientAppId = Get-VariableValue -Map $Variables -Name 'EXO_CLIENT_ID' -Fallback $env:EXO_CLIENT_ID
        if ([string]::IsNullOrWhiteSpace($clientAppId)) {
            $clientAppId = Get-VariableValue -Map $Variables -Name 'MS_CLIENT_ID' -Fallback $env:MS_CLIENT_ID
        }

        $tenantId = Get-VariableValue -Map $Variables -Name 'EXO_TENANT_ID' -Fallback $env:EXO_TENANT_ID
        if ([string]::IsNullOrWhiteSpace($tenantId)) {
            $tenantId = Get-VariableValue -Map $Variables -Name 'MS_TENANT_ID' -Fallback $env:MS_TENANT_ID
        }

        $clientSecret = Get-VariableValue -Map $Variables -Name 'EXO_CLIENT_SECRET' -Fallback $env:EXO_CLIENT_SECRET
        if ([string]::IsNullOrWhiteSpace($clientSecret)) {
            $clientSecret = Get-VariableValue -Map $Variables -Name 'MS_CLIENT_SECRET' -Fallback $env:MS_CLIENT_SECRET
        }

        Write-Host "`nRunning chained Work IQ bootstrap..." -ForegroundColor Cyan

        try {
            & $workIqBootstrapScript `
                -ClientAppId $clientAppId `
                -ClientSecret $clientSecret `
                -TenantId $tenantId `
                -PersistScope $PersistScope `
                -DoNotUpdateCurrentSession:$DoNotUpdateCurrentSession.IsPresent `
                -SkipValidation:$SkipValidation.IsPresent `
                -ContinueOnError:$ContinueOnError.IsPresent
        }
        catch {
            $workIqBootstrapFailed = $true
            if ($ContinueOnError.IsPresent) {
                Write-Warning "Work IQ bootstrap failed: $($_.Exception.Message)"
            }
            else {
                throw
            }
        }
    }
}

Write-Host "`nBootstrap complete." -ForegroundColor Green

if ($failureCount -gt 0 -or $workIqBootstrapFailed) {
    exit 1
}

exit 0
