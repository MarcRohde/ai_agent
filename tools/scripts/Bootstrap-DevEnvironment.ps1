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

.EXAMPLE
    .\Bootstrap-DevEnvironment.ps1 -Variables @{
        TENANT_ID='7d2c093d-4c2f-41e8-b222-0039fd152112'
        CLIENT_ID='a27799c8-18f2-4b9a-bdb7-ea913b465d70'
    }

.EXAMPLE
    .\Bootstrap-DevEnvironment.ps1 -Variables @{API_KEY='secret'} -PersistScope Machine

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
    [switch]$SkipValidation
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

# Pre-flight checks
Write-Host "Dev Environment Bootstrap" -ForegroundColor Cyan
Write-Host ("=" * 50)

if ($PersistScope -eq 'Machine' -and -not (Test-IsAdmin)) {
    Write-Error "Machine scope requires Administrator privileges. Re-run PowerShell as Administrator or use '-PersistScope User'."
    exit 1
}

if ($Variables.Count -eq 0) {
    Write-Warning "No variables provided. Nothing to do."
    exit 0
}

# Set variables
$updateSession = -not $DoNotUpdateCurrentSession.IsPresent
$successCount = 0
$failureCount = 0
$results = @()

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

Write-Host "`nBootstrap complete." -ForegroundColor Green

if ($failureCount -gt 0) {
    exit 1
}

exit 0
