<#
.SYNOPSIS
    Acquire a Microsoft Graph access token for local automation scripts.

.DESCRIPTION
    Resolves a Graph access token from one of four sources:
    1) Existing environment variable (validated for expiry)
    2) Cached refresh token (attempts automatic renewal)
    3) Azure CLI logged-in account (with optional automatic browser login)
    4) Device code flow (requires client ID)

    Refresh tokens are cached for autonomous operation on repeat runs.

.PARAMETER AccessTokenEnvVar
    Name of the environment variable that stores the access token.
    Default: M365_GRAPH_ACCESS_TOKEN

.PARAMETER TenantId
    Entra tenant identifier or domain.
    Defaults to environment variable EXO_TENANT_ID, then 'organizations'.

.PARAMETER ClientId
    Public client application ID used for device code flow and refresh token.
    Required only when -UseDeviceCode is specified or Azure CLI fallback fails.

.PARAMETER Scope
    Space-delimited scopes used for device code flow.
    Default: User.Read Files.Read.All Sites.Read.All offline_access

.PARAMETER UseDeviceCode
    Force device code flow and skip Azure CLI lookup.

.PARAMETER SkipAzureCliLogin
    Skip automatic browser-based az login when Azure CLI is available but no token exists.

.PARAMETER SaveToUserEnv
    Persist token to user environment variable instead of process-only variable.

.EXAMPLE
    .\tools\scripts\M365\Get-M365GraphAccessToken.ps1

.EXAMPLE
    .\tools\scripts\M365\Get-M365GraphAccessToken.ps1 -UseDeviceCode -ClientId "<app-id>"

.NOTES
    Author: AI Agent
    Date: 2026-03-08
    Features: Refresh token caching, JWT validation, browser fallback chain
#>

[CmdletBinding()]
param(
    [string]$AccessTokenEnvVar = 'M365_GRAPH_ACCESS_TOKEN',
    [string]$TenantId,
    [string]$ClientId,
    [string]$Scope = 'User.Read Files.Read.All Sites.Read.All offline_access',
    [switch]$UseDeviceCode,
    [switch]$SkipAzureCliLogin,
    [switch]$SaveToUserEnv
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:AzureCliErrorCode = ''

function Test-StringEmpty {
    param([string]$Value)
    return [string]::IsNullOrWhiteSpace($Value)
}

function Test-ValidJwt {
    param([string]$Token)
    if (Test-StringEmpty $Token) { return $false }
    $parts = $Token -split '\.'
    if ($parts.Count -ne 3) { return $false }
    try {
        $payload = $parts[1].Replace('-', '+').Replace('_', '/')
        $padding = 4 - ($payload.Length % 4)
        if ($padding -lt 4) { $payload += ('=' * $padding) }
        $bytes = [System.Convert]::FromBase64String($payload)
        $text = [System.Text.Encoding]::UTF8.GetString($bytes)
        $obj = $text | ConvertFrom-Json
        if ($obj.exp) {
            $now = [int]([DateTime]::UtcNow.Subtract([DateTime]::new(1970, 1, 1)).TotalSeconds)
            return $obj.exp -gt $now
        }
        return $false
    }
    catch { return $false }
}

function Get-TokenFromAzureCli {
    param([bool]$TryInteractiveLogin = $true, [string]$LoginTenant = '')
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) { return $null }
    try {
        $token = & az account get-access-token --resource-type ms-graph --query accessToken -o tsv 2>&1
        if ($token -and -not (Test-StringEmpty $token)) { return $token.Trim() }
    }
    catch { if ($_.Exception.Message -match 'AADSTS65002') { $script:AzureCliErrorCode = 'AADSTS65002' } }
    if (-not $TryInteractiveLogin) { return $null }
    $loginArgs = @('login')
    if (-not (Test-StringEmpty $LoginTenant) -and $LoginTenant -ne 'organizations') { $loginArgs += @('--tenant', $LoginTenant) }
    Write-Host 'Launching browser login (az login)...' -ForegroundColor Yellow
    try {
        $null = & az @loginArgs 2>&1
        $token = & az account get-access-token --resource-type ms-graph --query accessToken -o tsv 2>&1
        if ($token -and -not (Test-StringEmpty $token)) { return $token.Trim() }
    }
    catch { if ($_.Exception.Message -match 'AADSTS65002') { $script:AzureCliErrorCode = 'AADSTS65002' } }
    return $null
}

function Open-UrlInBrowser {
    param([string]$Url)
    $browsers = @('msedge.exe', 'chrome.exe', 'firefox.exe', 'iexplore.exe')
    foreach ($browser in $browsers) {
        if (Get-Command $browser -ErrorAction SilentlyContinue) {
            try { Start-Process $browser -ArgumentList $Url -ErrorAction Stop; return $true }
            catch { continue }
        }
    }
    try { Start-Process $Url -ErrorAction Stop; return $true }
    catch { return $false }
}

function Copy-ToClipboard {
    param([string]$Value)
    try { Set-Clipboard -Value $Value -ErrorAction Stop; return $true }
    catch { Write-Verbose "Clipboard unavailable: $($_.Exception.Message)"; return $false }
}

function Get-TokenFromDeviceCode {
    param([string]$Tenant, [string]$PublicClientId, [string]$RequestedScope, [string]$RefreshTokenEnvVar = '')
    $deviceCodeUri = "https://login.microsoftonline.com/$Tenant/oauth2/v2.0/devicecode"
    $tokenUri = "https://login.microsoftonline.com/$Tenant/oauth2/v2.0/token"
    try {
        $response = Invoke-RestMethod -Method Post -Uri $deviceCodeUri -ContentType 'application/x-www-form-urlencoded' `
            -Body @{ client_id = $PublicClientId; scope = $RequestedScope } -ErrorAction Stop
    }
    catch { throw "Failed to request device code: $($_.Exception.Message)" }

    $clipboardOk = Copy-ToClipboard -Value $response.user_code
    $browserOk = Open-UrlInBrowser -Url $response.verification_uri
    Write-Host "" -ForegroundColor Cyan
    Write-Host "=== SIGN IN REQUIRED ===" -ForegroundColor Cyan
    Write-Host "Device Code: $($response.user_code)" -ForegroundColor Yellow
    if ($clipboardOk) { Write-Host "(code copied to clipboard)" -ForegroundColor Green }
    Write-Host "Navigate to: $($response.verification_uri)" -ForegroundColor Green
    Write-Host "=========================" -ForegroundColor Cyan
    Write-Host ""

    $interval = [Math]::Max(3, $response.interval)
    $expires = (Get-Date).AddSeconds($response.expires_in)

    while ((Get-Date) -lt $expires) {
        Start-Sleep -Seconds $interval
        try {
            $tokenResp = Invoke-RestMethod -Method Post -Uri $tokenUri -ContentType 'application/x-www-form-urlencoded' `
                -Body @{ grant_type = 'urn:ietf:params:oauth:grant-type:device_code'; client_id = $PublicClientId; device_code = $response.device_code } `
                -ErrorAction Stop
            if ($tokenResp.access_token -and (Test-ValidJwt $tokenResp.access_token)) {
                if ($tokenResp.refresh_token -and -not (Test-StringEmpty $RefreshTokenEnvVar)) {
                    [Environment]::SetEnvironmentVariable($RefreshTokenEnvVar, $tokenResp.refresh_token, 'User')
                }
                return $tokenResp.access_token
            }
        }
        catch {
            $err = ''
            if ($null -ne $_.ErrorDetails -and -not [string]::IsNullOrWhiteSpace($_.ErrorDetails.Message)) {
                $err = $_.ErrorDetails.Message
            }
            elseif ($null -ne $_.Exception -and -not [string]::IsNullOrWhiteSpace($_.Exception.Message)) {
                $err = $_.Exception.Message
            }

            if ($err -match 'authorization_pending') { continue }
            if ($err -match 'slow_down') { $interval = [Math]::Min($interval + 5, 120); continue }
            if ($err -match 'declined|expired|bad_verification') { throw "Device code flow failed: $err" }
            if ($_.Exception.Message -match 'timeout|temporary') { Write-Verbose "Temporary error: $($_.Exception.Message)"; continue }
            throw
        }
    }
    throw 'Device code flow timed out.'
}

function Get-TokenFromRefresh {
    param([string]$Tenant, [string]$PublicClientId, [string]$RefreshToken, [string]$RequestedScope)
    $tokenUri = "https://login.microsoftonline.com/$Tenant/oauth2/v2.0/token"
    try {
        $resp = Invoke-RestMethod -Method Post -Uri $tokenUri -ContentType 'application/x-www-form-urlencoded' `
            -Body @{ grant_type = 'refresh_token'; client_id = $PublicClientId; refresh_token = $RefreshToken; scope = $RequestedScope } `
            -ErrorAction Stop
        if ($resp.access_token -and (Test-ValidJwt $resp.access_token)) { return $resp.access_token }
    }
    catch { Write-Verbose "Refresh token flow failed: $($_.Exception.Message)" }
    return $null
}

# Resolve tenant and client
if (Test-StringEmpty $TenantId) {
    $TenantId = if (-not (Test-StringEmpty $env:EXO_TENANT_ID)) { $env:EXO_TENANT_ID } else { 'organizations' }
}
if ((Test-StringEmpty $ClientId) -and -not (Test-StringEmpty $env:EXO_CLIENT_ID)) {
    $ClientId = $env:EXO_CLIENT_ID
}

# 1. Check existing valid token
$token = [Environment]::GetEnvironmentVariable($AccessTokenEnvVar, 'Process')
if (Test-StringEmpty $token) { $token = [Environment]::GetEnvironmentVariable($AccessTokenEnvVar, 'User') }
if (Test-StringEmpty $token) { $token = [Environment]::GetEnvironmentVariable($AccessTokenEnvVar, 'Machine') }

if (-not (Test-StringEmpty $token) -and (Test-ValidJwt $token)) {
    Write-Output $token
    exit 0
}

# 2. Try refresh token
$refreshVar = $AccessTokenEnvVar -replace 'ACCESS_TOKEN', 'REFRESH_TOKEN'
if (-not $UseDeviceCode) {
    $refresh = [Environment]::GetEnvironmentVariable($refreshVar, 'User')
    if (-not (Test-StringEmpty $refresh)) {
        Write-Verbose "Attempting refresh token..."
        $newToken = Get-TokenFromRefresh -Tenant $TenantId -PublicClientId $ClientId -RefreshToken $refresh -RequestedScope $Scope
        if (-not (Test-StringEmpty $newToken)) {
            $scope = if ($SaveToUserEnv) { 'User' } else { 'Process' }
            [Environment]::SetEnvironmentVariable($AccessTokenEnvVar, $newToken, $scope)
            Write-Output $newToken
            exit 0
        }
    }
}

# 3. Try Azure CLI
$token = $null
if (-not $UseDeviceCode) {
    $token = Get-TokenFromAzureCli -TryInteractiveLogin (-not $SkipAzureCliLogin.IsPresent) -LoginTenant $TenantId
}

# 4. Fall back to device code
if (Test-StringEmpty $token) {
    if (Test-StringEmpty $ClientId) {
        if ($script:AzureCliErrorCode -eq 'AADSTS65002') { throw 'Azure CLI OAuth blocked (AADSTS65002). Set EXO_CLIENT_ID for device code flow.' }
        if ($SkipAzureCliLogin.IsPresent) { throw 'No token. Remove -SkipAzureCliLogin or set EXO_CLIENT_ID.' }
        if (-not (Get-Command az -ErrorAction SilentlyContinue)) { throw 'Azure CLI not installed. Set EXO_CLIENT_ID for device code flow.' }
        throw 'No token found. Set EXO_CLIENT_ID for device code flow.'
    }
    $token = Get-TokenFromDeviceCode -Tenant $TenantId -PublicClientId $ClientId -RequestedScope $Scope -RefreshTokenEnvVar $refreshVar
}

# 5. Cache and output
$scope = if ($SaveToUserEnv) { 'User' } else { 'Process' }
[Environment]::SetEnvironmentVariable($AccessTokenEnvVar, $token, $scope)
Write-Output $token
