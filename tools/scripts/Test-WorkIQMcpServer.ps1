# Test-WorkIQMcpServer.ps1
# Validates a Work IQ MCP HTTP endpoint by initializing an MCP session, listing
# tools, and optionally calling one read-only tool.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Endpoint,

    [Parameter(Mandatory = $true)]
    [string]$TokenEnvVar,

    [Parameter(Mandatory = $true)]
    [string]$ExpectedToolPrefix,

    [string]$ServerAlias = 'workiq-server',
    [string]$ReadOnlyToolName,
    [hashtable]$ReadOnlyToolArguments = @{},
    [int]$PreviewToolCount = 5,
    [switch]$SkipToolCall,
    [string]$ShowToolSchema
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-StringEmpty {
    param([string]$Value)
    return [string]::IsNullOrWhiteSpace($Value)
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

function Convert-ToPreviewText {
    param(
        [object]$Value,
        [int]$MaxLength = 4000
    )

    if ($null -eq $Value) {
        return ''
    }

    if ($Value -is [string]) {
        $text = $Value
    }
    else {
        $text = $Value | ConvertTo-Json -Depth 20
    }

    if ($MaxLength -gt 0 -and $text.Length -gt $MaxLength) {
        return ($text.Substring(0, $MaxLength) + "`n... (output truncated at $MaxLength chars)")
    }

    return $text
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

    $response = Invoke-WebRequest -Method Post -Uri $Uri -Headers $Headers -ContentType 'application/json' -Body ($payload | ConvertTo-Json -Depth 20 -Compress)
    $body = $null

    if (-not [string]::IsNullOrWhiteSpace($response.Content)) {
        $content = $response.Content.Trim()

        # MCP servers may return JSON directly or JSON embedded in SSE frames.
        if ($content -match '^(event|data):') {
            $jsonObjects = @()
            $dataLines = $response.Content -split "`r?`n" | Where-Object { $_ -like 'data:*' }
            foreach ($line in $dataLines) {
                $candidate = $line.Substring(5).Trim()
                if ([string]::IsNullOrWhiteSpace($candidate) -or $candidate -eq '[DONE]') {
                    continue
                }

                try {
                    $jsonObjects += ($candidate | ConvertFrom-Json -Depth 20)
                }
                catch {
                    # Ignore non-JSON data frames and keep scanning.
                }
            }

            if ($jsonObjects.Count -gt 0) {
                $body = $jsonObjects[$jsonObjects.Count - 1]
            }
            else {
                $body = $response.Content
            }
        }
        else {
            try {
                $body = $response.Content | ConvertFrom-Json -Depth 20
            }
            catch {
                $body = $response.Content
            }
        }
    }

    return [pscustomobject]@{
        Response = $response
        Body     = $body
    }
}

$token = [Environment]::GetEnvironmentVariable($TokenEnvVar, 'Process')
if (Test-StringEmpty $token) {
    $token = [Environment]::GetEnvironmentVariable($TokenEnvVar, 'User')
}
if (Test-StringEmpty $token) {
    $token = [Environment]::GetEnvironmentVariable($TokenEnvVar, 'Machine')
}

if (Test-StringEmpty $token) {
    Write-Error "Token environment variable $TokenEnvVar is not set. Run the corresponding Set-WorkIQ...Token script first."
    exit 1
}

$protocolVersions = @('2025-03-26', '2024-11-05')
$lastFailure = $null

foreach ($protocolVersion in $protocolVersions) {
    $headers = @{
        Authorization          = "Bearer $token"
        Accept                 = 'application/json, text/event-stream'
        'MCP-Protocol-Version' = $protocolVersion
    }

    try {
        $initialize = Invoke-McpRequest -Uri $Endpoint -Headers $headers -Method 'initialize' -Params ([ordered]@{
                protocolVersion = $protocolVersion
                capabilities    = @{}
                clientInfo      = [ordered]@{
                    name    = 'ai-agent-workiq-smoke-test'
                    version = '1.0.0'
                }
            }) -Id 'initialize-1'

        $initializeError = $null
        if ($null -ne $initialize.Body -and $initialize.Body -is [psobject] -and $null -ne $initialize.Body.PSObject.Properties['error']) {
            $initializeError = $initialize.Body.error
        }
        if ($null -ne $initializeError) {
            throw "Initialize failed: $($initializeError.message)"
        }

        $sessionId = Get-HeaderValue -Headers $initialize.Response.Headers -Name 'Mcp-Session-Id'
        if (-not (Test-StringEmpty $sessionId)) {
            $headers['Mcp-Session-Id'] = $sessionId
        }

        $null = Invoke-McpRequest -Uri $Endpoint -Headers $headers -Method 'notifications/initialized' -Params $null -Id $null
        $toolsResponse = Invoke-McpRequest -Uri $Endpoint -Headers $headers -Method 'tools/list' -Params @{} -Id 'tools-1'

        $toolsError = $null
        if ($null -ne $toolsResponse.Body -and $toolsResponse.Body -is [psobject] -and $null -ne $toolsResponse.Body.PSObject.Properties['error']) {
            $toolsError = $toolsResponse.Body.error
        }
        if ($null -ne $toolsError) {
            throw "tools/list failed: $($toolsError.message)"
        }

        if ($null -eq $toolsResponse.Body -or -not ($toolsResponse.Body -is [psobject]) -or $null -eq $toolsResponse.Body.PSObject.Properties['result']) {
            throw 'tools/list returned an unexpected response shape.'
        }

        $tools = @($toolsResponse.Body.result.tools)
        $toolNamePattern = if ($ExpectedToolPrefix -match '[\*\?\[]') { $ExpectedToolPrefix } else { "$ExpectedToolPrefix*" }
        $matchingTools = @($tools | Where-Object { $_.name -like $toolNamePattern })

        if ($matchingTools.Count -eq 0) {
            throw "No tools with prefix $ExpectedToolPrefix were returned."
        }

        Write-Host ''
        Write-Host "Connected to $ServerAlias" -ForegroundColor Green
        Write-Host "Protocol version: $protocolVersion" -ForegroundColor Gray
        if (-not (Test-StringEmpty $sessionId)) {
            Write-Host 'Session ID: received' -ForegroundColor Gray
        }
        Write-Host "Matched tools: $($matchingTools.Count)" -ForegroundColor Gray
        Write-Host ''
        $matchingTools | Select-Object -First $PreviewToolCount -Property name, description | Format-Table -Wrap -AutoSize

        if (-not (Test-StringEmpty $ShowToolSchema)) {
            $schemaTool = $tools | Where-Object { $_.name -eq $ShowToolSchema } | Select-Object -First 1
            if ($null -eq $schemaTool) {
                throw "Tool '$ShowToolSchema' was not found."
            }

            Write-Host ''
            Write-Host "Tool schema for $ShowToolSchema" -ForegroundColor Yellow
            $schemaTool | ConvertTo-Json -Depth 30
            exit 0
        }

        if (-not $SkipToolCall -and -not (Test-StringEmpty $ReadOnlyToolName)) {
            $toolCall = Invoke-McpRequest -Uri $Endpoint -Headers $headers -Method 'tools/call' -Params ([ordered]@{
                    name      = $ReadOnlyToolName
                    arguments = $ReadOnlyToolArguments
                }) -Id 'tool-call-1'

            $toolCallError = $null
            if ($null -ne $toolCall.Body -and $toolCall.Body -is [psobject] -and $null -ne $toolCall.Body.PSObject.Properties['error']) {
                $toolCallError = $toolCall.Body.error
            }
            if ($null -ne $toolCallError) {
                throw "tools/call failed: $($toolCallError.message)"
            }

            $toolResult = $null
            if ($null -ne $toolCall.Body -and $toolCall.Body -is [psobject] -and $null -ne $toolCall.Body.PSObject.Properties['result']) {
                $toolResult = $toolCall.Body.result
            }

            if ($null -ne $toolResult -and $toolResult -is [psobject] -and $null -ne $toolResult.PSObject.Properties['isError'] -and [bool]$toolResult.isError) {
                $toolErrorPreview = Convert-ToPreviewText -Value $toolResult
                throw "tools/call returned isError=true: $toolErrorPreview"
            }

            Write-Host ''
            Write-Host "Read-only tool call succeeded: $ReadOnlyToolName" -ForegroundColor Green

            # Try to extract the 'reply' field from the first text content item (M365 Copilot search results).
            $displayed = $false
            if ($null -ne $toolResult -and $toolResult -is [psobject] -and $null -ne $toolResult.PSObject.Properties['content']) {
                $firstContent = @($toolResult.content) | Where-Object { $_.type -eq 'text' } | Select-Object -First 1
                if ($null -ne $firstContent) {
                    try {
                        $parsed = $firstContent.text | ConvertFrom-Json -Depth 20
                        if ($null -ne $parsed.PSObject.Properties['reply'] -and -not [string]::IsNullOrWhiteSpace($parsed.reply)) {
                            Write-Host ''
                            Write-Host $parsed.reply
                            $displayed = $true
                        }
                    }
                    catch {}
                }
            }

            if (-not $displayed) {
                $preview = Convert-ToPreviewText -Value $toolResult -MaxLength 0
                if (-not (Test-StringEmpty $preview)) {
                    Write-Host $preview -ForegroundColor Gray
                }
            }
        }

        exit 0
    }
    catch {
        $lastFailure = $_
    }
}

throw "Work IQ MCP validation failed for $ServerAlias. $($lastFailure.Exception.Message)"
