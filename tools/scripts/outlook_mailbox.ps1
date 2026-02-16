<#
.SYNOPSIS
    Interact with Outlook mailbox via Microsoft Graph REST API.

.DESCRIPTION
    Provides read, search, send, reply, summarize, and list-folders operations
    against the authenticated user's Outlook mailbox. Uses Invoke-MgGraphRequest
    (from Microsoft.Graph.Authentication) so no sub-modules are required.

    Requires: Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
    Then:     Connect-MgGraph -Scopes "Mail.Read","Mail.Send","Mail.ReadWrite"

.PARAMETER Operation
    The operation to perform: Read, Search, Send, Reply, Summarize, ListFolders.

.PARAMETER Count
    Number of messages to retrieve (default: 10, max: 50).

.PARAMETER Folder
    Mail folder name (default: Inbox).

.PARAMETER Query
    Search query string (for Search operation).

.PARAMETER MessageId
    Specific message ID (for Reply or single-message read).

.PARAMETER To
    Recipient email address (for Send).

.PARAMETER Subject
    Email subject (for Send).

.PARAMETER Body
    Email body text (for Send / Reply).

.PARAMETER SummaryScope
    Scope for Summarize: "today", "unread", "last-week" (default: "today").

.EXAMPLE
    .\outlook_mailbox.ps1 -Operation Read -Count 5
    .\outlook_mailbox.ps1 -Operation Search -Query "budget report"
    .\outlook_mailbox.ps1 -Operation Send -To "user@example.com" -Subject "Hello" -Body "Test message"
    .\outlook_mailbox.ps1 -Operation Summarize -SummaryScope "unread"
    .\outlook_mailbox.ps1 -Operation ListFolders
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet("Read", "Search", "Send", "Reply", "Summarize", "ListFolders")]
    [string]$Operation,

    [int]$Count = 10,
    [string]$Folder = "Inbox",
    [string]$Query = "",
    [string]$MessageId = "",
    [string]$To = "",
    [string]$Subject = "",
    [string]$Body = "",
    [string]$SummaryScope = "today"
)

$ErrorActionPreference = "Stop"

# ─── Helpers ──────────────────────────────────────────────────────────────────

function Assert-GraphConnection {
    try {
        $ctx = Get-MgContext
        if (-not $ctx) { throw "No context" }
        Write-Verbose "Connected as $($ctx.Account)"
    }
    catch {
        Write-Error @"
Not connected to Microsoft Graph.
Run:  Connect-MgGraph -Scopes "Mail.Read","Mail.Send","Mail.ReadWrite"
"@
        exit 1
    }
}

function Invoke-Graph {
    param(
        [string]$Method = "GET",
        [string]$Uri,
        [object]$Body = $null
    )
    $params = @{
        Method = $Method
        Uri    = $Uri
    }
    if ($Body) {
        $params.Body = ($Body | ConvertTo-Json -Depth 10)
        $params.ContentType = "application/json"
    }
    Invoke-MgGraphRequest @params
}

function Get-WellKnownFolderPath {
    param([string]$FolderName)
    $map = @{
        "Inbox"         = "Inbox"
        "SentItems"     = "SentItems"
        "Sent Items"    = "SentItems"
        "Drafts"        = "Drafts"
        "Archive"       = "Archive"
        "DeletedItems"  = "DeletedItems"
        "Deleted Items" = "DeletedItems"
        "JunkEmail"     = "JunkEmail"
        "Junk"          = "JunkEmail"
    }
    if ($map.ContainsKey($FolderName)) { return $map[$FolderName] }

    # Try to find by display name
    $result = Invoke-Graph -Uri "/v1.0/me/mailFolders?`$filter=displayName eq '$FolderName'"
    if ($result.value -and $result.value.Count -gt 0) {
        return $result.value[0].id
    }
    Write-Warning "Folder '$FolderName' not found. Falling back to Inbox."
    return "Inbox"
}

function Format-MessageRow {
    param([object]$Msg, [int]$Index)
    $unread = if ($Msg.isRead -eq $false) { [char]0x2709 } else { "" }
    $fromAddr = if ($Msg.from -and $Msg.from.emailAddress) { $Msg.from.emailAddress.address } else { "(unknown)" }
    $date = if ($Msg.receivedDateTime) {
        ([datetime]$Msg.receivedDateTime).ToString("yyyy-MM-dd HH:mm")
    } else { "" }
    [PSCustomObject]@{
        "#"       = $Index
        From      = $fromAddr
        Subject   = $Msg.subject
        Date      = $date
        Unread    = $unread
        MessageId = $Msg.id
    }
}

# ─── Operations ───────────────────────────────────────────────────────────────

function Invoke-ReadMail {
    $folderId = Get-WellKnownFolderPath -FolderName $Folder
    $top = [Math]::Min($Count, 50)
    $select = "id,subject,from,receivedDateTime,isRead,bodyPreview"

    $uri = "/v1.0/me/mailFolders/$folderId/messages?`$top=$top&`$orderby=receivedDateTime desc&`$select=$select"
    $result = Invoke-Graph -Uri $uri

    $messages = $result.value
    if (-not $messages -or $messages.Count -eq 0) {
        Write-Host "No messages found in $Folder."
        return
    }

    $i = 1
    $rows = $messages | ForEach-Object { Format-MessageRow -Msg $_ -Index ($i++); $i++ } | Select-Object -First $top
    # Rebuild rows cleanly
    $rows = @()
    $i = 1
    foreach ($msg in $messages) {
        $rows += Format-MessageRow -Msg $msg -Index $i
        $i++
    }
    $rows | Format-Table "#", From, Subject, Date, Unread -AutoSize | Out-String | Write-Host

    # Preview first message
    $first = $messages[0]
    $fromAddr = if ($first.from -and $first.from.emailAddress) { $first.from.emailAddress.address } else { "(unknown)" }
    Write-Host "`n--- Preview: Message #1 ---"
    Write-Host "From:    $fromAddr"
    Write-Host "Subject: $($first.subject)"
    Write-Host "Date:    $($first.receivedDateTime)"
    Write-Host ""
    Write-Host $first.bodyPreview
}

function Invoke-SearchMail {
    if (-not $Query) {
        Write-Error "Search requires -Query parameter."
        exit 1
    }

    $folderId = Get-WellKnownFolderPath -FolderName $Folder
    $top = [Math]::Min($Count, 50)
    $select = "id,subject,from,receivedDateTime,isRead,bodyPreview"
    $searchEncoded = [uri]::EscapeDataString("`"$Query`"")

    $uri = "/v1.0/me/mailFolders/$folderId/messages?`$search=$searchEncoded&`$top=$top&`$select=$select"
    $result = Invoke-Graph -Uri $uri

    $messages = $result.value
    if (-not $messages -or $messages.Count -eq 0) {
        Write-Host "No messages matching '$Query' in $Folder."
        return
    }

    Write-Host "Search results for: '$Query'"
    $rows = @(); $i = 1
    foreach ($msg in $messages) { $rows += Format-MessageRow -Msg $msg -Index $i; $i++ }
    $rows | Format-Table "#", From, Subject, Date, Unread -AutoSize | Out-String | Write-Host
}

function Invoke-SendMail {
    if (-not $To) { Write-Error "Send requires -To parameter."; exit 1 }
    if (-not $Subject) { Write-Error "Send requires -Subject parameter."; exit 1 }
    if (-not $Body) { Write-Error "Send requires -Body parameter."; exit 1 }

    $payload = @{
        message = @{
            subject = $Subject
            body = @{
                contentType = "Text"
                content = $Body
            }
            toRecipients = @(
                @{ emailAddress = @{ address = $To } }
            )
        }
        saveToSentItems = $true
    }

    Invoke-Graph -Method POST -Uri "/v1.0/me/sendMail" -Body $payload
    Write-Host "Email sent successfully."
    Write-Host "  To:      $To"
    Write-Host "  Subject: $Subject"
    Write-Host "  Time:    $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
}

function Invoke-ReplyMail {
    if (-not $MessageId) { Write-Error "Reply requires -MessageId parameter."; exit 1 }
    if (-not $Body) { Write-Error "Reply requires -Body parameter."; exit 1 }

    # Fetch original for context
    $original = Invoke-Graph -Uri "/v1.0/me/messages/$MessageId`?`$select=subject,from,receivedDateTime,bodyPreview"
    $fromAddr = if ($original.from -and $original.from.emailAddress) { $original.from.emailAddress.address } else { "(unknown)" }

    Write-Host "Replying to:"
    Write-Host "  From:    $fromAddr"
    Write-Host "  Subject: $($original.subject)"
    Write-Host "  Date:    $($original.receivedDateTime)"
    Write-Host ""

    $payload = @{ comment = $Body }
    Invoke-Graph -Method POST -Uri "/v1.0/me/messages/$MessageId/reply" -Body $payload
    Write-Host "Reply sent successfully."
}

function Invoke-SummarizeMail {
    $folderId = Get-WellKnownFolderPath -FolderName $Folder

    $filter = switch ($SummaryScope) {
        "today" {
            $todayStart = (Get-Date).Date.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            "receivedDateTime ge $todayStart"
        }
        "unread" { "isRead eq false" }
        "last-week" {
            $weekAgo = (Get-Date).AddDays(-7).Date.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            "receivedDateTime ge $weekAgo"
        }
        default { "isRead eq false" }
    }

    $filterEncoded = [uri]::EscapeDataString($filter)
    $select = "id,subject,from,receivedDateTime,isRead,bodyPreview,importance"
    $uri = "/v1.0/me/mailFolders/$folderId/messages?`$filter=$filterEncoded&`$top=50&`$orderby=receivedDateTime desc&`$select=$select"
    $result = Invoke-Graph -Uri $uri

    $messages = $result.value
    if (-not $messages -or $messages.Count -eq 0) {
        Write-Host "No messages found for scope: $SummaryScope"
        return
    }

    $total = $messages.Count
    $unread = ($messages | Where-Object { $_.isRead -eq $false }).Count
    $highImportance = @($messages | Where-Object { $_.importance -eq "high" })

    Write-Host "=== Email Summary ($SummaryScope) ==="
    Write-Host "Total: $total | Unread: $unread | High importance: $($highImportance.Count)"
    Write-Host ""

    if ($highImportance.Count -gt 0) {
        Write-Host "--- High Importance ---"
        foreach ($msg in $highImportance) {
            $fromAddr = if ($msg.from -and $msg.from.emailAddress) { $msg.from.emailAddress.address } else { "(unknown)" }
            Write-Host "  ! $fromAddr - $($msg.subject)"
        }
        Write-Host ""
    }

    # Group by sender
    $grouped = $messages | Group-Object { if ($_.from -and $_.from.emailAddress) { $_.from.emailAddress.address } else { "(unknown)" } }
    foreach ($group in ($grouped | Sort-Object Count -Descending)) {
        Write-Host "--- $($group.Name) ($($group.Count) emails) ---"
        foreach ($msg in $group.Group) {
            $readMark = if ($msg.isRead -eq $false) { "[UNREAD] " } else { "" }
            $preview = if ($msg.bodyPreview) {
                ($msg.bodyPreview -replace '\s+', ' ').Substring(0, [Math]::Min(100, $msg.bodyPreview.Length))
            } else { "" }
            Write-Host "  ${readMark}$($msg.subject)"
            Write-Host "    $preview..."
        }
        Write-Host ""
    }

    # Structured JSON output for agent parsing
    $summary = @{
        Scope = $SummaryScope
        Total = $total
        Unread = $unread
        HighImportance = $highImportance.Count
        Messages = @($messages | ForEach-Object {
            @{
                Id = $_.id
                From = if ($_.from -and $_.from.emailAddress) { $_.from.emailAddress.address } else { "(unknown)" }
                Subject = $_.subject
                Date = if ($_.receivedDateTime) { ([datetime]$_.receivedDateTime).ToString("yyyy-MM-dd HH:mm") } else { "" }
                IsRead = $_.isRead
                Importance = $_.importance
                Preview = $_.bodyPreview
            }
        })
    }
    Write-Host "`n=== JSON ==="
    $summary | ConvertTo-Json -Depth 4
}

function Invoke-ListFolders {
    $result = Invoke-Graph -Uri "/v1.0/me/mailFolders?`$top=50&`$select=displayName,totalItemCount,unreadItemCount"

    $folders = $result.value
    if (-not $folders -or $folders.Count -eq 0) {
        Write-Host "No mail folders found."
        return
    }

    $folders | Sort-Object { $_.totalItemCount } -Descending |
        ForEach-Object {
            [PSCustomObject]@{
                Folder = $_.displayName
                Total  = $_.totalItemCount
                Unread = $_.unreadItemCount
            }
        } | Format-Table -AutoSize | Out-String | Write-Host
}

# ─── Main ─────────────────────────────────────────────────────────────────────

Assert-GraphConnection

switch ($Operation) {
    "Read"        { Invoke-ReadMail }
    "Search"      { Invoke-SearchMail }
    "Send"        { Invoke-SendMail }
    "Reply"       { Invoke-ReplyMail }
    "Summarize"   { Invoke-SummarizeMail }
    "ListFolders" { Invoke-ListFolders }
}
