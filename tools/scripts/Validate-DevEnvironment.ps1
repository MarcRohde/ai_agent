<#
.SYNOPSIS
    Validate development environment configuration.

.DESCRIPTION
    Checks that required environment variables are set and optionally validates
    tool installations, connectivity, and other prerequisites.

.PARAMETER RequiredVariables
    Array of environment variable names that must be set.

.PARAMETER ValidateTools
    Hashtable of tools to validate. Format: @{ToolName='version-command'}
    Example: @{git='git --version'; python='python --version'}

.PARAMETER ValidateConnectivity
    Array of URLs to test connectivity (optional).

.PARAMETER Quiet
    Suppress detailed output, only show pass/fail summary.

.EXAMPLE
    .\Validate-DevEnvironment.ps1 -RequiredVariables @('TENANT_ID','CLIENT_ID')

.EXAMPLE
    .\Validate-DevEnvironment.ps1 -RequiredVariables @('API_KEY') -ValidateTools @{git='git --version'}

.NOTES
    Author: AI Agent
    Date: 2026-03-02
    Returns exit code 0 on success, 1 if any validation fails
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$RequiredVariables = @(),

    [Parameter(Mandatory = $false)]
    [hashtable]$ValidateTools = @{},

    [Parameter(Mandatory = $false)]
    [string[]]$ValidateConnectivity = @(),

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$checks = @()
$overallPass = $true

if (-not $Quiet) {
    Write-Host "Environment Validation" -ForegroundColor Cyan
    Write-Host ("=" * 50)
    Write-Host ""
}

# Check required environment variables
if ($RequiredVariables.Count -gt 0) {
    if (-not $Quiet) {
        Write-Host "Checking Environment Variables:" -ForegroundColor White
    }

    foreach ($varName in $RequiredVariables) {
        $value = [Environment]::GetEnvironmentVariable($varName, 'User')
        if (-not $value) {
            $value = [Environment]::GetEnvironmentVariable($varName, 'Machine')
        }
        if (-not $value) {
            $value = [Environment]::GetEnvironmentVariable($varName, 'Process')
        }

        $isSet = -not [string]::IsNullOrWhiteSpace($value)
        $status = if ($isSet) { 'PASS' } else { 'FAIL' }
        $displayValue = if ($isSet) {
            if ($varName -match 'SECRET|PASSWORD|KEY|TOKEN') { '***' } else { $value }
        }
        else { '' }

        $checks += [PSCustomObject]@{
            Check  = $varName
            Status = $status
            Value  = $displayValue
        }

        if (-not $Quiet) {
            $color = if ($isSet) { 'Green' } else { 'Red' }
            Write-Host "  $varName : " -NoNewline
            Write-Host $status -ForegroundColor $color
        }

        if (-not $isSet) {
            $overallPass = $false
        }
    }

    if (-not $Quiet) {
        Write-Host ""
    }
}

# Check tool installations
if ($ValidateTools.Count -gt 0) {
    if (-not $Quiet) {
        Write-Host "Checking Tool Installations:" -ForegroundColor White
    }

    foreach ($entry in $ValidateTools.GetEnumerator()) {
        $toolName = $entry.Key
        $versionCommand = $entry.Value

        try {
            $output = Invoke-Expression $versionCommand 2>&1
            $isInstalled = $LASTEXITCODE -eq 0 -or $output
            $status = if ($isInstalled) { 'PASS' } else { 'FAIL' }
            $version = if ($isInstalled) { ($output | Select-Object -First 1) } else { 'Not found' }
        }
        catch {
            $isInstalled = $false
            $status = 'FAIL'
            $version = 'Not found'
        }

        $checks += [PSCustomObject]@{
            Check  = "$toolName installed"
            Status = $status
            Value  = $version
        }

        if (-not $Quiet) {
            $color = if ($isInstalled) { 'Green' } else { 'Red' }
            Write-Host "  $toolName : " -NoNewline
            Write-Host $status -ForegroundColor $color
        }

        if (-not $isInstalled) {
            $overallPass = $false
        }
    }

    if (-not $Quiet) {
        Write-Host ""
    }
}

# Check connectivity
if ($ValidateConnectivity.Count -gt 0) {
    if (-not $Quiet) {
        Write-Host "Checking Connectivity:" -ForegroundColor White
    }

    foreach ($url in $ValidateConnectivity) {
        try {
            $response = Invoke-WebRequest -Uri $url -Method HEAD -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
            $isReachable = $response.StatusCode -eq 200
            $status = if ($isReachable) { 'PASS' } else { 'FAIL' }
            $value = "HTTP $($response.StatusCode)"
        }
        catch {
            $isReachable = $false
            $status = 'FAIL'
            $value = $_.Exception.Message
        }

        $checks += [PSCustomObject]@{
            Check  = $url
            Status = $status
            Value  = $value
        }

        if (-not $Quiet) {
            $color = if ($isReachable) { 'Green' } else { 'Red' }
            Write-Host "  $url : " -NoNewline
            Write-Host $status -ForegroundColor $color
        }

        if (-not $isReachable) {
            $overallPass = $false
        }
    }

    if (-not $Quiet) {
        Write-Host ""
    }
}

# Summary
if (-not $Quiet) {
    Write-Host ("=" * 50)
}

if ($overallPass) {
    Write-Host "Environment Validation: PASSED" -ForegroundColor Green
    if (-not $Quiet) {
        Write-Host "All checks passed. Environment is ready." -ForegroundColor Green
    }
    exit 0
}
else {
    Write-Host "Environment Validation: FAILED" -ForegroundColor Red

    if (-not $Quiet) {
        $failedChecks = $checks | Where-Object { $_.Status -eq 'FAIL' }
        Write-Host "`nFailed checks:" -ForegroundColor Red
        $failedChecks | Format-Table -AutoSize

        # Provide remediation guidance
        $missingVars = $failedChecks | Where-Object { $_.Check -in $RequiredVariables }
        if ($missingVars) {
            Write-Host "`nTo fix missing environment variables, run:" -ForegroundColor Yellow
            Write-Host "  .\Bootstrap-DevEnvironment.ps1 -Variables @{" -ForegroundColor Gray
            foreach ($var in $missingVars) {
                Write-Host "      $($var.Check) = '<value>'" -ForegroundColor Gray
            }
            Write-Host "  }" -ForegroundColor Gray
        }
    }

    exit 1
}
