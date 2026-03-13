# Set-WorkIQAllTokens.ps1
# Retrieves and stores bearer tokens for all enabled Work IQ MCP servers.

[CmdletBinding()]
param(
    [string]$CatalogPath,
    [string]$ClientAppId = $env:EXO_CLIENT_ID,
    [string]$TenantId = $env:EXO_TENANT_ID,
    [string[]]$Aliases = @(),
    [switch]$Refresh,
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
    throw 'No Work IQ servers selected for token setup.'
}

if ([string]::IsNullOrWhiteSpace($ClientAppId)) {
    throw 'Client app ID not provided. Set EXO_CLIENT_ID or pass -ClientAppId.'
}

$tokenScript = Join-Path $PSScriptRoot 'Set-WorkIQMcpToken.ps1'
if (-not (Test-Path $tokenScript)) {
    throw "Token helper script not found: $tokenScript"
}

$pwshCommand = Get-Command pwsh -ErrorAction SilentlyContinue
if ($null -eq $pwshCommand) {
    throw 'pwsh executable not found. Install PowerShell 7 to run token setup orchestration.'
}

$pwshExe = $pwshCommand.Source
$results = @()

Write-Host ''
Write-Host 'Setting Work IQ MCP tokens...' -ForegroundColor Cyan
Write-Host "Servers: $($targetServers.Count)" -ForegroundColor Gray

foreach ($server in $targetServers) {
    $alias = [string]$server.alias
    $scope = [string]$server.scope
    $tokenEnvVar = [string]$server.tokenEnvVar

    if ([string]::IsNullOrWhiteSpace($alias) -or [string]::IsNullOrWhiteSpace($scope) -or [string]::IsNullOrWhiteSpace($tokenEnvVar)) {
        $msg = "Catalog entry is missing alias/scope/tokenEnvVar. Alias='$alias' Scope='$scope' TokenEnvVar='$tokenEnvVar'"
        if ($ContinueOnError.IsPresent) {
            Write-Warning $msg
            $results += [pscustomobject]@{
                Alias       = $alias
                Scope       = $scope
                TokenEnvVar = $tokenEnvVar
                Status      = 'FAILED'
                TokenLength = 0
                Note        = 'Catalog entry incomplete'
            }
            continue
        }

        throw $msg
    }

    $invokeArgs = @(
        '-NoProfile',
        '-File', $tokenScript,
        '-Scope', $scope,
        '-TokenEnvVar', $tokenEnvVar,
        '-ServerAlias', $alias,
        '-ClientAppId', $ClientAppId
    )

    if (-not [string]::IsNullOrWhiteSpace($TenantId)) {
        $invokeArgs += @('-TenantId', $TenantId)
    }
    if ($Refresh.IsPresent) {
        $invokeArgs += '-Refresh'
    }

    Write-Host ''
    Write-Host "[$alias] requesting token..." -ForegroundColor Yellow
    & $pwshExe @invokeArgs
    $exitCode = $LASTEXITCODE

    $tokenValue = [Environment]::GetEnvironmentVariable($tokenEnvVar, 'User')
    if (-not [string]::IsNullOrWhiteSpace($tokenValue)) {
        Set-Item -Path "Env:$tokenEnvVar" -Value $tokenValue
    }

    $ok = ($exitCode -eq 0) -and (-not [string]::IsNullOrWhiteSpace($tokenValue))

    $results += [pscustomobject]@{
        Alias       = $alias
        Scope       = $scope
        TokenEnvVar = $tokenEnvVar
        Status      = if ($ok) { 'OK' } else { 'FAILED' }
        TokenLength = if ($ok) { $tokenValue.Length } else { 0 }
        Note        = if ($ok) { '' } else { "ExitCode=$exitCode" }
    }

    if (-not $ok -and -not $ContinueOnError.IsPresent) {
        throw "Token setup failed for $alias ($scope)."
    }
}

Write-Host ''
Write-Host 'Work IQ token setup summary' -ForegroundColor Cyan
$results | Format-Table -AutoSize

$failed = @($results | Where-Object { $_.Status -eq 'FAILED' })
if ($failed.Count -gt 0) {
    $failedAliases = ($failed | ForEach-Object { $_.Alias }) -join ', '
    if ($ContinueOnError.IsPresent) {
        Write-Warning "Token setup completed with failures: $failedAliases"
    }
    else {
        throw "Token setup failed for: $failedAliases"
    }
}
