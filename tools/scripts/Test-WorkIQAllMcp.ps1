# Test-WorkIQAllMcp.ps1
# Runs Work IQ MCP connectivity and tool discovery checks for all configured servers.

[CmdletBinding()]
param(
    [string]$CatalogPath,
    [string[]]$Aliases = @(),
    [int]$PreviewToolCount = 5,
    [switch]$SkipToolCall,
    [switch]$ContinueOnError,
    [switch]$IncludeDisabled
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ([string]::IsNullOrWhiteSpace($CatalogPath)) {
    $CatalogPath = Join-Path $repoRoot 'config\work_iq_mcp\catalog.json'
}

if (-not (Test-Path $CatalogPath)) {
    throw "Catalog file not found: $CatalogPath"
}

$catalog = Get-Content -Path $CatalogPath -Raw | ConvertFrom-Json -Depth 50
$catalogServers = @($catalog.servers)
if ($catalogServers.Count -eq 0) {
    throw "No Work IQ servers found in catalog: $CatalogPath"
}

$targetServers = if ($Aliases.Count -gt 0) {
    @($catalogServers | Where-Object { $Aliases -contains [string]$_.alias })
}
elseif ($IncludeDisabled.IsPresent) {
    $catalogServers
}
else {
    @($catalogServers | Where-Object { $_.enabledInVscode -eq $true })
}

if ($targetServers.Count -eq 0) {
    throw 'No Work IQ servers selected for validation.'
}

$testScript = Join-Path $PSScriptRoot 'Test-WorkIQMcpServer.ps1'
if (-not (Test-Path $testScript)) {
    throw "Validation helper script not found: $testScript"
}

$pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
if ($null -eq $pwshCommand) {
    throw 'pwsh executable not found. Install PowerShell 7 to run MCP validation orchestration.'
}

$pwshExe = $pwshCommand.Source
$results = @()

Write-Host ''
Write-Host 'Validating Work IQ MCP servers...' -ForegroundColor Cyan
Write-Host "Servers: $($targetServers.Count)" -ForegroundColor Gray

foreach ($server in $targetServers) {
    $alias = [string]$server.alias
    $endpoint = [string]$server.endpoint
    $tokenEnvVar = [string]$server.tokenEnvVar

    if ([string]::IsNullOrWhiteSpace($alias) -or [string]::IsNullOrWhiteSpace($endpoint) -or [string]::IsNullOrWhiteSpace($tokenEnvVar)) {
        $msg = "Catalog entry is missing alias/endpoint/tokenEnvVar. Alias='$alias' Endpoint='$endpoint' TokenEnvVar='$tokenEnvVar'"
        if ($ContinueOnError.IsPresent) {
            Write-Warning $msg
            $results += [pscustomobject]@{
                Alias       = $alias
                TokenEnvVar = $tokenEnvVar
                Status      = 'FAILED'
                Note        = 'Catalog entry incomplete'
            }
            continue
        }

        throw $msg
    }

    $invokeArgs = @(
        '-NoProfile',
        '-File', $testScript,
        '-Endpoint', $endpoint,
        '-TokenEnvVar', $tokenEnvVar,
        '-ExpectedToolPrefix', '*',
        '-ServerAlias', $alias,
        '-PreviewToolCount', [string]$PreviewToolCount
    )

    if ($SkipToolCall.IsPresent) {
        $invokeArgs += '-SkipToolCall'
    }

    Write-Host ''
    Write-Host "[$alias] running connectivity check..." -ForegroundColor Yellow
    & $pwshExe @invokeArgs
    $exitCode = $LASTEXITCODE

    $ok = $exitCode -eq 0
    $results += [pscustomobject]@{
        Alias       = $alias
        TokenEnvVar = $tokenEnvVar
        Status      = if ($ok) { 'OK' } else { 'FAILED' }
        Note        = if ($ok) { '' } else { "ExitCode=$exitCode" }
    }

    if (-not $ok -and -not $ContinueOnError.IsPresent) {
        throw "Validation failed for $alias"
    }
}

Write-Host ''
Write-Host 'Work IQ MCP validation summary' -ForegroundColor Cyan
$results | Format-Table -AutoSize

$failed = @($results | Where-Object { $_.Status -eq 'FAILED' })
if ($failed.Count -gt 0) {
    $failedAliases = ($failed | ForEach-Object { $_.Alias }) -join ', '
    if ($ContinueOnError.IsPresent) {
        Write-Warning "Validation completed with failures: $failedAliases"
    }
    else {
        throw "Validation failed for: $failedAliases"
    }
}
