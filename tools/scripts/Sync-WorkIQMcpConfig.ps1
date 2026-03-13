# Sync-WorkIQMcpConfig.ps1
# Rebuilds .vscode/mcp.json Work IQ entries from config/work_iq_mcp/catalog.json
# while preserving non-Work IQ MCP server entries.

[CmdletBinding()]
param(
    [string]$CatalogPath,
    [string]$McpConfigPath,
    [switch]$IncludeDisabled
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ([string]::IsNullOrWhiteSpace($CatalogPath)) {
    $CatalogPath = Join-Path $repoRoot 'config\work_iq_mcp\catalog.json'
}
if ([string]::IsNullOrWhiteSpace($McpConfigPath)) {
    $McpConfigPath = Join-Path $repoRoot '.vscode\mcp.json'
}

if (-not (Test-Path $CatalogPath)) {
    throw "Catalog file not found: $CatalogPath"
}

$catalog = Get-Content -Path $CatalogPath -Raw | ConvertFrom-Json -Depth 50
$catalogServers = @($catalog.servers)
if ($catalogServers.Count -eq 0) {
    throw "No Work IQ servers found in catalog: $CatalogPath"
}

$targetServers = if ($IncludeDisabled.IsPresent) {
    $catalogServers
}
else {
    @($catalogServers | Where-Object { $_.enabledInVscode -eq $true })
}

if ($targetServers.Count -eq 0) {
    throw 'No enabled Work IQ servers found to write into MCP config.'
}

$existingServers = [ordered]@{}
if (Test-Path $McpConfigPath) {
    $existingConfig = Get-Content -Path $McpConfigPath -Raw | ConvertFrom-Json -Depth 50
    if ($null -ne $existingConfig.PSObject.Properties['servers']) {
        foreach ($prop in $existingConfig.servers.PSObject.Properties) {
            $existingServers[$prop.Name] = $prop.Value
        }
    }
}

$workIqAliases = @($catalogServers | ForEach-Object { [string]$_.alias })
$newServers = [ordered]@{}

# Preserve non-Work IQ server entries that already exist in mcp.json.
foreach ($name in $existingServers.Keys) {
    if ($workIqAliases -notcontains $name) {
        $newServers[$name] = $existingServers[$name]
    }
}

foreach ($server in $targetServers) {
    $alias = [string]$server.alias
    $endpoint = [string]$server.endpoint
    $tokenEnvVar = [string]$server.tokenEnvVar

    if ([string]::IsNullOrWhiteSpace($alias)) {
        throw 'Catalog server entry is missing alias.'
    }
    if ([string]::IsNullOrWhiteSpace($endpoint)) {
        throw "Catalog server '$alias' is missing endpoint."
    }
    if ([string]::IsNullOrWhiteSpace($tokenEnvVar)) {
        throw "Catalog server '$alias' is missing tokenEnvVar."
    }

    $newServers[$alias] = [ordered]@{
        type    = 'http'
        url     = $endpoint
        headers = [ordered]@{
            Authorization = ('Bearer ${env:' + $tokenEnvVar + '}')
        }
    }
}

$outConfig = [ordered]@{
    servers = $newServers
}

$outDir = Split-Path -Parent $McpConfigPath
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

$json = $outConfig | ConvertTo-Json -Depth 20
Set-Content -Path $McpConfigPath -Value ($json + [Environment]::NewLine) -Encoding UTF8

Write-Host ''
Write-Host 'Synced VS Code MCP config from Work IQ catalog.' -ForegroundColor Green
Write-Host "Catalog: $CatalogPath" -ForegroundColor Gray
Write-Host "MCP config: $McpConfigPath" -ForegroundColor Gray
Write-Host "Work IQ servers written: $($targetServers.Count)" -ForegroundColor Gray
