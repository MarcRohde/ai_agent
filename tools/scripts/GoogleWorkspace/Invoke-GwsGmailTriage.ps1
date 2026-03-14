<#
.SYNOPSIS
    Fast Gmail triage wrapper for gws CLI.

.DESCRIPTION
    Provides Phase 1 workflow acceleration commands for Gmail:
    - find: retrieve messages for a query with key headers
    - sweep: dry-run or apply trash operations with keep/delete filters
    - verify: check whether target messages are in TRASH

    Phase 1 guarantees:
    - single-entry workflow for find/sweep/verify
    - dry-run is default for sweep actions
    - destructive operations require both -Apply and -ConfirmDelete
    - operation artifact JSON is written for every run
    - post-delete verification checks TRASH label state

    Safety defaults:
    - sweep runs in dry-run mode unless -Apply is set
    - destructive execution requires both -Apply and -ConfirmDelete
    - writes an operation artifact JSON file for auditability

.EXAMPLE
    # Find last 20 messages from Chase
    .\tools\scripts\GoogleWorkspace\Invoke-GwsGmailTriage.ps1 -Action find -Query 'from:chase' -MaxResults 20

.EXAMPLE
    # Dry-run sweep: delete from Chase except daily summaries
    .\tools\scripts\GoogleWorkspace\Invoke-GwsGmailTriage.ps1 -Action sweep -Query 'from:chase' -MaxResults 100 -KeepSubjectPattern 'daily summary'

.EXAMPLE
    # Apply sweep with explicit confirmation
    .\tools\scripts\GoogleWorkspace\Invoke-GwsGmailTriage.ps1 -Action sweep -Query 'from:chase' -MaxResults 100 -Apply -ConfirmDelete

.EXAMPLE
    # Verify explicit IDs
    .\tools\scripts\GoogleWorkspace\Invoke-GwsGmailTriage.ps1 -Action verify -Ids 'abc123','def456'
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('find', 'sweep', 'verify')]
    [string]$Action,

    [string]$Query = '',

    [ValidateRange(1, 5000)]
    [int]$MaxResults = 100,

    [ValidateRange(1, 500)]
    [int]$PageSize = 100,

    [string[]]$Ids = @(),

    [string[]]$KeepFromPattern = @(),
    [string[]]$KeepSubjectPattern = @(),

    [string[]]$DeleteFromPattern = @(),
    [string[]]$DeleteSubjectPattern = @(),

    [string]$UserId = 'me',

    [switch]$Apply,
    [switch]$ConfirmDelete,
    [switch]$Quiet,

    [string]$OutputPath = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Info {
    param([string]$Message)

    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor Gray
    }
}

function Test-AnyRegexMatch {
    param(
        [string]$Value,
        [string[]]$Patterns
    )

    if ($Patterns.Count -eq 0) {
        return $false
    }

    foreach ($pattern in $Patterns) {
        if ([string]::IsNullOrWhiteSpace($pattern)) {
            continue
        }

        if ($Value -match $pattern) {
            return $true
        }
    }

    return $false
}

function Assert-GwsAvailable {
    $null = Get-Command gws -ErrorAction Stop
}

function ConvertFrom-GwsRawJson {
    param([string[]]$RawLines)

    $filtered = @($RawLines | Where-Object { $_ -notmatch '^Using keyring backend:' })
    $rawText = ($filtered -join "`n").Trim()

    if ([string]::IsNullOrWhiteSpace($rawText)) {
        throw 'gws returned empty output.'
    }

    try {
        $obj = $rawText | ConvertFrom-Json -Depth 100
    }
    catch {
        throw "Unable to parse gws JSON output. Raw output: $rawText"
    }

    if ($null -ne $obj.PSObject.Properties['error']) {
        $msg = $obj.error.message
        if ([string]::IsNullOrWhiteSpace($msg)) {
            $msg = 'Unknown gws error.'
        }
        throw "gws returned error: $msg"
    }

    return $obj
}

function Invoke-GwsJson {
    param([string[]]$Arguments)

    $raw = & gws @Arguments 2>&1
    return ConvertFrom-GwsRawJson -RawLines $raw
}

function Get-GmailMessageIds {
    param(
        [string]$UserId,
        [string]$Query,
        [int]$MaxResults,
        [int]$PageSize
    )

    $ids = New-Object System.Collections.Generic.List[string]
    $nextPageToken = $null

    do {
        $remaining = $MaxResults - $ids.Count
        if ($remaining -le 0) {
            break
        }

        $pageLimit = [Math]::Min($PageSize, $remaining)

        $params = [ordered]@{
            userId     = $UserId
            maxResults = $pageLimit
        }

        if (-not [string]::IsNullOrWhiteSpace($Query)) {
            $params.q = $Query
        }

        if (-not [string]::IsNullOrWhiteSpace($nextPageToken)) {
            $params.pageToken = $nextPageToken
        }

        $response = Invoke-GwsJson -Arguments @(
            'gmail', 'users', 'messages', 'list',
            '--params', ($params | ConvertTo-Json -Compress)
        )

        if ($response.messages) {
            foreach ($message in $response.messages) {
                $ids.Add([string]$message.id)
            }
        }

        $nextPageToken = if ($null -ne $response.PSObject.Properties['nextPageToken']) {
            [string]$response.nextPageToken
        }
        else {
            $null
        }
    }
    while (-not [string]::IsNullOrWhiteSpace($nextPageToken))

    return @($ids)
}

function Get-GmailMessageRecord {
    param(
        [string]$UserId,
        [string]$Id
    )

    $params = [ordered]@{
        userId = $UserId
        id     = $Id
        format = 'full'
    }

    $message = Invoke-GwsJson -Arguments @(
        'gmail', 'users', 'messages', 'get',
        '--params', ($params | ConvertTo-Json -Compress)
    )

    $headerLookup = @{}
    foreach ($header in @($message.payload.headers)) {
        if ($null -eq $header.name) {
            continue
        }

        $name = [string]$header.name
        if (-not $headerLookup.ContainsKey($name)) {
            $headerLookup[$name] = [string]$header.value
        }
    }

    return [pscustomobject]@{
        Id       = $Id
        ThreadId = [string]$message.threadId
        Date     = if ($headerLookup.ContainsKey('Date')) { $headerLookup['Date'] } else { '' }
        From     = if ($headerLookup.ContainsKey('From')) { $headerLookup['From'] } else { '' }
        Subject  = if ($headerLookup.ContainsKey('Subject')) { $headerLookup['Subject'] } else { '' }
        LabelIds = @($message.labelIds)
    }
}

function Move-GmailMessageToTrash {
    param(
        [string]$UserId,
        [string]$Id
    )

    $params = [ordered]@{
        userId = $UserId
        id     = $Id
    }

    $trashResponse = Invoke-GwsJson -Arguments @(
        'gmail', 'users', 'messages', 'trash',
        '--params', ($params | ConvertTo-Json -Compress)
    )

    return @($trashResponse.labelIds) -contains 'TRASH'
}

function Get-SweepDecisions {
    param(
        [object[]]$Records,
        [string[]]$KeepFromPattern,
        [string[]]$KeepSubjectPattern,
        [string[]]$DeleteFromPattern,
        [string[]]$DeleteSubjectPattern
    )

    $useDeleteFilters = ($DeleteFromPattern.Count -gt 0) -or ($DeleteSubjectPattern.Count -gt 0)

    $output = foreach ($record in $Records) {
        $keepReason = ''

        if (Test-AnyRegexMatch -Value $record.From -Patterns $KeepFromPattern) {
            $keepReason = 'keep-from-pattern'
        }
        elseif (Test-AnyRegexMatch -Value $record.Subject -Patterns $KeepSubjectPattern) {
            $keepReason = 'keep-subject-pattern'
        }

        $deleteFilterMatch = $true
        if ($useDeleteFilters) {
            $deleteFilterMatch = (Test-AnyRegexMatch -Value $record.From -Patterns $DeleteFromPattern) -or
            (Test-AnyRegexMatch -Value $record.Subject -Patterns $DeleteSubjectPattern)
        }

        $decision = 'delete'
        $reason = 'eligible'

        if (-not [string]::IsNullOrWhiteSpace($keepReason)) {
            $decision = 'keep'
            $reason = $keepReason
        }
        elseif (-not $deleteFilterMatch) {
            $decision = 'keep'
            $reason = 'delete-filter-no-match'
        }

        [pscustomobject]@{
            Id       = $record.Id
            Date     = $record.Date
            From     = $record.From
            Subject  = $record.Subject
            Decision = $decision
            Reason   = $reason
        }
    }

    return @($output)
}

function Save-OperationArtifact {
    param(
        [object]$Result,
        [string]$OutputPath,
        [string]$Action
    )

    $resolvedPath = $OutputPath
    if ([string]::IsNullOrWhiteSpace($resolvedPath)) {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $resolvedPath = Join-Path $env:TEMP ("gws_gmail_{0}_{1}.json" -f $Action, $timestamp)
    }

    $directory = Split-Path -Path $resolvedPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
    }

    $Result | ConvertTo-Json -Depth 15 | Set-Content -Path $resolvedPath -Encoding utf8
    return $resolvedPath
}

Assert-GwsAvailable
Write-Info "Action: $Action"

$result = $null

switch ($Action) {
    'find' {
        if ([string]::IsNullOrWhiteSpace($Query) -and $Ids.Count -eq 0) {
            throw 'For Action=find, provide -Query or explicit -Ids.'
        }

        $targetIds = if ($Ids.Count -gt 0) {
            @($Ids | Select-Object -Unique)
        }
        else {
            Get-GmailMessageIds -UserId $UserId -Query $Query -MaxResults $MaxResults -PageSize $PageSize
        }

        $records = foreach ($id in $targetIds) {
            Get-GmailMessageRecord -UserId $UserId -Id $id
        }

        $result = [pscustomobject]@{
            action      = 'find'
            query       = $Query
            maxResults  = $MaxResults
            count       = @($records).Count
            generatedAt = (Get-Date).ToString('o')
            items       = @($records)
        }

        Write-Host ("Found {0} messages." -f @($records).Count)
    }

    'sweep' {
        if ([string]::IsNullOrWhiteSpace($Query) -and $Ids.Count -eq 0) {
            throw 'For Action=sweep, provide -Query or explicit -Ids.'
        }

        $targetIds = if ($Ids.Count -gt 0) {
            @($Ids | Select-Object -Unique)
        }
        else {
            Get-GmailMessageIds -UserId $UserId -Query $Query -MaxResults $MaxResults -PageSize $PageSize
        }

        $records = foreach ($id in $targetIds) {
            Get-GmailMessageRecord -UserId $UserId -Id $id
        }

        $decisions = Get-SweepDecisions -Records @($records) -KeepFromPattern $KeepFromPattern -KeepSubjectPattern $KeepSubjectPattern -DeleteFromPattern $DeleteFromPattern -DeleteSubjectPattern $DeleteSubjectPattern
        $deleteItems = @($decisions | Where-Object { $_.Decision -eq 'delete' })
        $keepItems = @($decisions | Where-Object { $_.Decision -eq 'keep' })

        $executionMode = if ($Apply) { 'apply' } else { 'dry-run' }
        $execution = @()

        if ($Apply) {
            if (-not $ConfirmDelete) {
                throw 'Destructive sweep requires both -Apply and -ConfirmDelete.'
            }

            foreach ($item in $deleteItems) {
                $trashed = Move-GmailMessageToTrash -UserId $UserId -Id $item.Id
                $current = Get-GmailMessageRecord -UserId $UserId -Id $item.Id
                $verified = @($current.LabelIds) -contains 'TRASH'

                $execution += [pscustomobject]@{
                    Id       = $item.Id
                    Trashed  = $trashed
                    Verified = $verified
                    Status   = if ($trashed -and $verified) { 'success' } else { 'failed' }
                }
            }
        }

        $result = [pscustomobject]@{
            action      = 'sweep'
            query       = $Query
            maxResults  = $MaxResults
            mode        = $executionMode
            generatedAt = (Get-Date).ToString('o')
            totals      = [pscustomobject]@{
                candidates = @($decisions).Count
                toDelete   = @($deleteItems).Count
                kept       = @($keepItems).Count
            }
            decisions   = @($decisions)
            execution   = @($execution)
        }

        Write-Host ("Sweep mode={0}, candidates={1}, toDelete={2}, kept={3}" -f $executionMode, @($decisions).Count, @($deleteItems).Count, @($keepItems).Count)
    }

    'verify' {
        if ([string]::IsNullOrWhiteSpace($Query) -and $Ids.Count -eq 0) {
            throw 'For Action=verify, provide -Query or explicit -Ids.'
        }

        $targetIds = if ($Ids.Count -gt 0) {
            @($Ids | Select-Object -Unique)
        }
        else {
            Get-GmailMessageIds -UserId $UserId -Query $Query -MaxResults $MaxResults -PageSize $PageSize
        }

        $items = foreach ($id in $targetIds) {
            $record = Get-GmailMessageRecord -UserId $UserId -Id $id
            [pscustomobject]@{
                Id       = $record.Id
                From     = $record.From
                Subject  = $record.Subject
                InTrash  = (@($record.LabelIds) -contains 'TRASH')
                LabelIds = @($record.LabelIds)
            }
        }

        $result = [pscustomobject]@{
            action      = 'verify'
            query       = $Query
            maxResults  = $MaxResults
            generatedAt = (Get-Date).ToString('o')
            count       = @($items).Count
            inTrash     = @($items | Where-Object { $_.InTrash }).Count
            notInTrash  = @($items | Where-Object { -not $_.InTrash }).Count
            items       = @($items)
        }

        Write-Host ("Verified {0} messages (inTrash={1}, notInTrash={2})." -f @($items).Count, $result.inTrash, $result.notInTrash)
    }
}

$artifactPath = Save-OperationArtifact -Result $result -OutputPath $OutputPath -Action $Action
Write-Host "Artifact: $artifactPath"

$result
