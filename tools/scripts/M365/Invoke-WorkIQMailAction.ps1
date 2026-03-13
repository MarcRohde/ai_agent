<#
.SYNOPSIS
    Execute WorkIQ Mail MCP actions with safety checks and verification.

.DESCRIPTION
    Supports search/get/delete operations against WorkIQ Mail MCP.
    For destructive actions, this script enforces explicit confirmation,
    capability-aware fallback handling, and post-delete verification.

.NOTES
    Keep ItemIDs URL-encoded as supplied from OWA/citation links.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('search', 'get', 'delete')]
    [string]$Action,

    [string]$Query = '',
    [string]$ItemId = '',
    [string]$OwaUrl = '',

    [ValidateRange(1, 50)]
    [int]$Top = 10,

    [switch]$MoveToDeletedItems,
    [switch]$AllowDeleteFallback,
    [switch]$ConfirmDelete,
    [switch]$ConfirmDeleteFallback,

    [string]$Endpoint = 'https://agent365.svc.cloud.microsoft/agents/servers/mcp_MailTools/',
    [string]$TokenEnvVar = 'WORKIQ_MAIL_TOKEN',

    [switch]$Quiet,
    [switch]$AsJson
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-StringEmpty {
    param([string]$Value)
    return [string]::IsNullOrWhiteSpace($Value)
}

function Write-Info {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor Gray
    }
}

function Get-HeaderValue {
    param(
        [object]$Headers,
        [string]$Name
    )

    if ($null -eq $Headers) {
        return $null
    }

    foreach ($entry in $Headers.GetEnumerator()) {
        if ($entry.Key -ieq $Name) {
            if ($entry.Value -is [System.Array]) {
                return ($entry.Value -join ',')
            }
            return [string]$entry.Value
        }
    }

    return $null
}

function Convert-ToBody {
    param([object]$Response)

    if ($null -eq $Response -or [string]::IsNullOrWhiteSpace($Response.Content)) {
        return $null
    }

    $content = $Response.Content.Trim()

    if ($content -match '^(event|data):') {
        $jsonObjects = @()
        $dataLines = $Response.Content -split "`r?`n" | Where-Object { $_ -like 'data:*' }
        foreach ($line in $dataLines) {
            $candidate = $line.Substring(5).Trim()
            if ([string]::IsNullOrWhiteSpace($candidate) -or $candidate -eq '[DONE]') {
                continue
            }
            try {
                $jsonObjects += ($candidate | ConvertFrom-Json -Depth 30)
            }
            catch {
            }
        }

        if ($jsonObjects.Count -gt 0) {
            return $jsonObjects[$jsonObjects.Count - 1]
        }

        return $Response.Content
    }

    try {
        return ($Response.Content | ConvertFrom-Json -Depth 30)
    }
    catch {
        return $Response.Content
    }
}

function Invoke-McpRequest {
    param(
        [string]$Uri,
        [hashtable]$Headers,
        [string]$Method,
        [object]$Params,
        [object]$Id
    )

    $payload = [ordered]@{
        jsonrpc = '2.0'
        method  = $Method
    }

    if ($null -ne $Id) {
        $payload.id = $Id
    }

    if ($null -ne $Params) {
        $payload.params = $Params
    }

    $response = Invoke-WebRequest -Method Post -Uri $Uri -Headers $Headers -ContentType 'application/json' -Body ($payload | ConvertTo-Json -Depth 30 -Compress)
    $body = Convert-ToBody -Response $response

    return [pscustomobject]@{
        Response = $response
        Body     = $body
    }
}

function Get-TokenFromEnv {
    param([string]$EnvVarName)

    $token = [Environment]::GetEnvironmentVariable($EnvVarName, 'Process')
    if (Test-StringEmpty $token) {
        $token = [Environment]::GetEnvironmentVariable($EnvVarName, 'User')
    }
    if (Test-StringEmpty $token) {
        $token = [Environment]::GetEnvironmentVariable($EnvVarName, 'Machine')
    }

    return $token
}

function Get-McpSession {
    param(
        [string]$Endpoint,
        [string]$Token
    )

    $protocolVersions = @('2025-03-26', '2024-11-05')
    $lastFailure = $null

    foreach ($protocolVersion in $protocolVersions) {
        $headers = @{
            Authorization          = "Bearer $Token"
            Accept                 = 'application/json, text/event-stream'
            'MCP-Protocol-Version' = $protocolVersion
        }

        try {
            $init = Invoke-McpRequest -Uri $Endpoint -Headers $headers -Method 'initialize' -Params ([ordered]@{
                    protocolVersion = $protocolVersion
                    capabilities    = @{}
                    clientInfo      = [ordered]@{
                        name    = 'ai-agent-workiq-mail-action'
                        version = '1.0.0'
                    }
                }) -Id 'init-1'

            if ($null -ne $init.Body -and $init.Body -is [psobject] -and $null -ne $init.Body.PSObject.Properties['error']) {
                throw "initialize failed: $($init.Body.error.message)"
            }

            $sessionId = Get-HeaderValue -Headers $init.Response.Headers -Name 'Mcp-Session-Id'
            if (-not (Test-StringEmpty $sessionId)) {
                $headers['Mcp-Session-Id'] = $sessionId
            }

            $null = Invoke-McpRequest -Uri $Endpoint -Headers $headers -Method 'notifications/initialized' -Params $null -Id $null
            $toolsList = Invoke-McpRequest -Uri $Endpoint -Headers $headers -Method 'tools/list' -Params @{} -Id 'tools-1'

            if ($null -ne $toolsList.Body -and $toolsList.Body -is [psobject] -and $null -ne $toolsList.Body.PSObject.Properties['error']) {
                throw "tools/list failed: $($toolsList.Body.error.message)"
            }

            if ($null -eq $toolsList.Body -or -not ($toolsList.Body -is [psobject]) -or $null -eq $toolsList.Body.PSObject.Properties['result']) {
                throw 'tools/list returned unexpected response shape.'
            }

            return [pscustomobject]@{
                Endpoint = $Endpoint
                Headers  = $headers
                Tools    = @($toolsList.Body.result.tools)
                Protocol = $protocolVersion
            }
        }
        catch {
            $lastFailure = $_
        }
    }

    throw "Unable to initialize MCP session. $($lastFailure.Exception.Message)"
}

function Invoke-MailTool {
    param(
        [pscustomobject]$Session,
        [string]$ToolName,
        [hashtable]$Arguments
    )

    $resp = Invoke-McpRequest -Uri $Session.Endpoint -Headers $Session.Headers -Method 'tools/call' -Params ([ordered]@{
            name      = $ToolName
            arguments = $Arguments
        }) -Id ([guid]::NewGuid().ToString())

    if ($null -ne $resp.Body -and $resp.Body -is [psobject] -and $null -ne $resp.Body.PSObject.Properties['error']) {
        throw ('tools/call failed for {0}: {1}' -f $ToolName, $resp.Body.error.message)
    }

    $result = $null
    if ($null -ne $resp.Body -and $resp.Body -is [psobject] -and $null -ne $resp.Body.PSObject.Properties['result']) {
        $result = $resp.Body.result
    }

    if ($null -ne $result -and $result -is [psobject] -and $null -ne $result.PSObject.Properties['isError'] -and [bool]$result.isError) {
        $text = @($result.content | Where-Object { $_.type -eq 'text' } | Select-Object -First 1).text
        throw ('Tool {0} returned isError=true. {1}' -f $ToolName, $text)
    }

    return $result
}

function Test-EncodedItemId {
    param([string]$Value)

    if (Test-StringEmpty $Value) {
        return $false
    }

    if ($Value -match '%[0-9A-Fa-f]{2}') {
        return $true
    }

    return $false
}

function Get-ItemIdFromOwaUrl {
    param([string]$Value)

    if (Test-StringEmpty $Value) {
        return ''
    }

    try {
        $uri = [System.Uri]$Value
    }
    catch {
        throw 'OwaUrl is not a valid URI.'
    }

    foreach ($pair in ($uri.Query.TrimStart('?') -split '&')) {
        if ($pair -match '^(?<name>[^=]+)=(?<itemValue>.*)$' -and $Matches.name -ieq 'ItemID') {
            return $Matches.itemValue
        }
    }

    throw 'OwaUrl does not contain an ItemID query parameter.'
}

function New-Result {
    param(
        [bool]$Success,
        [string]$Action,
        [string]$OperationUsed,
        [bool]$FallbackUsed,
        [object]$Data,
        [string]$Verification,
        [string]$Warning,
        [string]$ErrorMessage
    )

    return [pscustomobject]@{
        success       = $Success
        action        = $Action
        operationUsed = $OperationUsed
        fallbackUsed  = $FallbackUsed
        verification  = $Verification
        warning       = $Warning
        data          = $Data
        error         = $ErrorMessage
    }
}

$token = Get-TokenFromEnv -EnvVarName $TokenEnvVar
if (Test-StringEmpty $token) {
    throw "Token environment variable '$TokenEnvVar' is not set. Run tools/scripts/Set-WorkIQMailToken.ps1 first."
}

$session = Get-McpSession -Endpoint $Endpoint -Token $token
$toolNames = @($session.Tools | ForEach-Object { $_.name })

if (Test-StringEmpty $ItemId -and -not (Test-StringEmpty $OwaUrl)) {
    $ItemId = Get-ItemIdFromOwaUrl -Value $OwaUrl
    Write-Info 'Extracted URL-encoded ItemID from OWA URL.'
}

Write-Info "Connected via protocol $($session.Protocol)."
Write-Info "Available tools: $($toolNames -join ', ')"

$fallbackUsed = $false
$operationUsed = ''
$warningText = ''
$verificationText = 'Not applicable'
$resultData = $null

switch ($Action) {
    'search' {
        if (Test-StringEmpty $Query) {
            throw 'Query is required for Action=search.'
        }

        if (-not ($toolNames -contains 'SearchMessages')) {
            throw 'SearchMessages is not available on this server.'
        }

        $operationUsed = 'SearchMessages'
        $searchQuery = $Query
        if ($Top -gt 0) {
            $searchQuery = "$Query (return up to $Top results)"
        }

        $resultData = Invoke-MailTool -Session $session -ToolName 'SearchMessages' -Arguments @{ message = $searchQuery }
    }

    'get' {
        if (Test-StringEmpty $ItemId) {
            throw 'ItemId is required for Action=get.'
        }

        if (-not (Test-EncodedItemId -Value $ItemId)) {
            throw 'ItemId does not appear URL-encoded. Use encoded OWA ItemID values only.'
        }

        if (-not ($toolNames -contains 'GetMessage')) {
            throw 'GetMessage is not available on this server.'
        }

        $operationUsed = 'GetMessage'
        $resultData = Invoke-MailTool -Session $session -ToolName 'GetMessage' -Arguments @{ id = $ItemId }
    }

    'delete' {
        if (Test-StringEmpty $ItemId) {
            throw 'ItemId is required for Action=delete.'
        }

        if (-not (Test-EncodedItemId -Value $ItemId)) {
            throw 'ItemId does not appear URL-encoded. Use encoded OWA ItemID values only.'
        }

        if (-not $ConfirmDelete.IsPresent) {
            throw 'Delete requires explicit confirmation. Rerun with -ConfirmDelete.'
        }

        if (-not ($toolNames -contains 'DeleteMessage')) {
            throw 'DeleteMessage is not available on this server.'
        }

        if ($toolNames -contains 'GetMessage') {
            try {
                $preview = Invoke-MailTool -Session $session -ToolName 'GetMessage' -Arguments @{ id = $ItemId }
                if (-not $Quiet) {
                    $previewText = @($preview.content | Where-Object { $_.type -eq 'text' } | Select-Object -First 1).text
                    if (-not (Test-StringEmpty $previewText)) {
                        Write-Host 'Delete target preview:' -ForegroundColor Yellow
                        Write-Host $previewText
                    }
                }
            }
            catch {
                Write-Info "Preview step could not retrieve message details: $($_.Exception.Message)"
            }
        }

        if ($MoveToDeletedItems.IsPresent) {
            if ($toolNames -contains 'MoveMessage') {
                try {
                    $operationUsed = 'MoveMessage'
                    $resultData = Invoke-MailTool -Session $session -ToolName 'MoveMessage' -Arguments @{ id = $ItemId; destinationId = 'deleteditems' }
                }
                catch {
                    if (-not $AllowDeleteFallback.IsPresent) {
                        throw "MoveMessage failed and delete fallback is not allowed. $($_.Exception.Message)"
                    }

                    if (-not $ConfirmDeleteFallback.IsPresent) {
                        throw 'MoveMessage failed/unavailable. Rerun with -ConfirmDeleteFallback to allow DeleteMessage fallback.'
                    }

                    $fallbackUsed = $true
                    $operationUsed = 'DeleteMessage'
                    $resultData = Invoke-MailTool -Session $session -ToolName 'DeleteMessage' -Arguments @{ id = $ItemId }
                }
            }
            else {
                if (-not $AllowDeleteFallback.IsPresent) {
                    throw 'MoveToDeletedItems requested but MoveMessage is unavailable. Rerun with -AllowDeleteFallback and -ConfirmDeleteFallback to proceed with delete.'
                }

                if (-not $ConfirmDeleteFallback.IsPresent) {
                    throw 'MoveMessage is unavailable. Rerun with -ConfirmDeleteFallback to confirm hard-delete fallback.'
                }

                $fallbackUsed = $true
                $operationUsed = 'DeleteMessage'
                $resultData = Invoke-MailTool -Session $session -ToolName 'DeleteMessage' -Arguments @{ id = $ItemId }
            }
        }
        else {
            $operationUsed = 'DeleteMessage'
            $resultData = Invoke-MailTool -Session $session -ToolName 'DeleteMessage' -Arguments @{ id = $ItemId }
        }

        if ($toolNames -contains 'GetMessage') {
            try {
                $null = Invoke-MailTool -Session $session -ToolName 'GetMessage' -Arguments @{ id = $ItemId }
                $verificationText = 'Delete requested, but GetMessage still returned the item.'
                $warningText = 'Verify mailbox state manually.'
            }
            catch {
                if ($_.Exception.Message -match 'not found in the store') {
                    $verificationText = 'Verified by GetMessage: item not found.'
                }
                else {
                    $verificationText = "Verification inconclusive: $($_.Exception.Message)"
                }
            }
        }
        else {
            $verificationText = 'GetMessage unavailable; verification skipped.'
        }
    }
}

$result = New-Result -Success $true -Action $Action -OperationUsed $operationUsed -FallbackUsed $fallbackUsed -Data $resultData -Verification $verificationText -Warning $warningText -ErrorMessage ''

if ($AsJson.IsPresent) {
    $result | ConvertTo-Json -Depth 20
}
else {
    if (-not $Quiet) {
        Write-Host "Action: $($result.action)" -ForegroundColor Green
        Write-Host "Operation Used: $($result.operationUsed)" -ForegroundColor Gray
        Write-Host "Fallback Used: $($result.fallbackUsed)" -ForegroundColor Gray
        Write-Host "Verification: $($result.verification)" -ForegroundColor Gray
        if (-not (Test-StringEmpty $result.warning)) {
            Write-Host "Warning: $($result.warning)" -ForegroundColor Yellow
        }
    }

    $result
}
